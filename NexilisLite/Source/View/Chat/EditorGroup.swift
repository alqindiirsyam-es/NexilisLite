//
//  EditorGroup.swift
//  Qmera
//
//  Created by Akhmad Al Qindi Irsyam on 20/09/21.
//

import UIKit
import AVKit
import AVFoundation
import QuickLook
import Photos
import NotificationBannerSwift
import nuSDKService
import SwiftLinkPreview
import SDWebImage
import PhotosUI

public class EditorGroup: UIViewController, CLLocationManagerDelegate {
    @IBOutlet var wallpaperView: UIImageView!
    @IBOutlet var viewButton: UIView!
    @IBOutlet var constraintViewTextField: NSLayoutConstraint!
    @IBOutlet var buttonVoice: UIButton!
    @IBOutlet var buttonSendImage: UIButton!
    @IBOutlet var buttonSendPhoto: UIButton!
    @IBOutlet var buttonSendSticker: UIButton!
    @IBOutlet var buttonSendFile: UIButton!
    @IBOutlet var textFieldSend: CustomTextView!
    @IBOutlet var heightTextFieldSend: NSLayoutConstraint!
    @IBOutlet var buttonSendChat: UIButton!
    @IBOutlet var tableChatView: UITableView!
    @IBOutlet var constraintTopTextField: NSLayoutConstraint!
    @IBOutlet var constraintBottomAttachment: NSLayoutConstraint!
    @IBOutlet var viewTextfield: UIView!
    @IBOutlet weak var buttonAckConfidential: UIButton!
    @IBOutlet weak var constraintBottomTableViewWithTextfield: NSLayoutConstraint!
    @IBOutlet weak var viewAttachment: UIStackView!
    @IBOutlet weak var tableMention: UITableView!
    @IBOutlet weak var heightTableMention: NSLayoutConstraint!
    @IBOutlet weak var contraintBottomMention: NSLayoutConstraint!
    public var dataGroup: [String: Any?] = [:]
    public var dataTopic: [String: Any?] = [:]
    var dataMessages: [[String: Any?]] = []
    var dataDates: [String] = []
    public var dataMessageForward: [[String: Any?]]?
    var imageVideoPicker: ImageVideoPicker!
    var documentPicker: DocumentPicker!
    var currentIndexpath: IndexPath?
    var previewItem: NSURL?
    var reffId: String?
    var stickers = [String]()
    public var unique_l_pin = ""
    public var fromNotification = false
    public var referenceMessageId = ""
    public var referenceChatDate = ""
    var isHistoryCC = false
    var complaintId = ""
    var counter = 0
    var markerCounter: String?
    var buttonScrollToBottom = UIButton()
    let indicatorCounterBSTB = UIView()
    let labelCounter = UILabel()
    let containerActionGroup = UIView()
    var removed = false
    var isConfidential = false
    var isAck = false
    var copySession = false
    var forwardSession = false
    var deleteSession = false
    var isSearching = false
    let containerMultpileSelectSession = UIView()
    let viewSticker = UIView()
    let containerLink = UIView()
    let containerPreviewReply = UIView()
    let containerPin = UIView()
    let textPin = UILabel()
    let signSelectedPin = UIStackView()
    var bottomAnchorPreviewReply = NSLayoutConstraint()
    let containerAction = UIView()
    var allowTyping = true
    let contactChatNav = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactChatNav") as! UINavigationController
    var searchBar: UISearchBar!
    var constraintBottomContainerMultpileSelectSession = NSLayoutConstraint()
    var titleSearchMatches: UILabel!
    var textSearch = ""
    var countMatchesSearch = 0
    var lastScrollIdxSearch = 0
    var nextPinShowed = 0
    var buttonUp: UIButton!
    var buttonDown: UIButton!
    var keyboardHeightForMention: CGFloat?
    var listMentionWithText:[User] = []
    var listMentionInTextField:[User] = []
    var tempListMentionWithText:[User] = []
    var tempListMentionInTextField:[User] = []
    var showingLink = ""
    var isAlwaysHideLinkPreview = false
    var timerCheckLink: Timer?
    var lastPositionCursorMention = 0
    var lastTextLength = 0
    var timerFakeProgress: Timer?
    var showMenuContext = false
    var touchedSubview = UIView()
    var listViewOnSection: [UIView] = []
    var fakeProgMultip = 0
    let maxFakeProgMultip = 2
    var groupImages: [String:[ImageGrouping]] = [:]
    var titleText: String!
    var lastY: CGFloat = 0
    var listTimerCredential: [String: Int] = [:]
    var timerCredential: [String: Timer] = [:]
    var editVC = UIViewController()
    var editTextView = CustomTextView()
    var isEditingMessage = false
    var constraintBottomeditTextView: NSLayoutConstraint!
    var constraintHeighteditTextView: NSLayoutConstraint!
    var constraintBottomSendEditTV: NSLayoutConstraint!
    let locationManager = CLLocationManager()
    var longitude = ""
    var latitude = ""
    var isBlackCancelButton = false
    let buttonSendEdit = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    
    var audioPlayers: [IndexPath: AVAudioPlayer] = [:]
    var timers: [IndexPath: Timer] = [:]
    var playingIndexPath: IndexPath?
    var timerSearch: Timer?
    
    var downloadList: [String: IndexPath] = [:]
    
    var transitioningDelegateRef: ZoomTransitioningDelegate?
    var buttonSpec = UIButton(type: .custom)
    var tableViewConfigFile: UITableView!
    var specFileString = ""
    
    var tableMentionEdit = UITableView()
    var heightTableEditMention: NSLayoutConstraint!
    
    func offset() -> CGFloat{
        guard let fontSize = Int(SecureUserDefaults.shared.value(forKey: "font_size") ?? "0") else { return 0 }
        return CGFloat(fontSize)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            removeAllObjectBeforeDismissVC()
        }
    }
    
    private func removeAllObjectBeforeDismissVC() {
        for timer in self.timerCredential.values {
            timer.invalidate()
        }
        SecureUserDefaults.shared.removeValue(forKey: "inEditorGroup")
        NotificationCenter.default.removeObserver(self)
        self.removeFromParent()
        var l_pin = self.dataGroup["group_id"]  as? String ?? ""
        if (self.dataTopic["chat_id"]  as? String ?? "" != "") {
            l_pin = self.dataTopic["chat_id"]  as? String ?? ""
        }
        var data: [String: Any] = ["text": self.textFieldSend.textColor != UIColor.lightGray ? self.textFieldSend.text! : "", "reffId": self.reffId ?? ""]
        if listMentionInTextField.count > 0 {
            var dataMention: [[String: String]] = []
            for list in listMentionInTextField {
                var dataTemp: [String: String] = [:]
                dataTemp["f_pin_mention"] = list.pin
                dataTemp["upper"] = list.ex_block
                dataMention.append(dataTemp)
            }
            data["list_mention"] = dataMention
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            SecureUserDefaults.shared.set(jsonString, forKey: "new_saved_\(l_pin)")
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.overrideUserInterfaceStyle = .dark
        self.setNeedsStatusBarAppearanceUpdate()
        navigationController?.navigationBar.barStyle = .black
        if self.navigationController?.isNavigationBarHidden ?? false {
            self.navigationController?.setNavigationBarHidden(false, animated: false)
        }
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationItem.largeTitleDisplayMode = .never
        updateProfile()
        let indexPath = tableChatView.indexPathsForVisibleRows?.first
        if indexPath != nil && currentIndexpath != nil {
            let headerRect = tableChatView.rectForHeader(inSection: indexPath!.section)
            let isPinned = headerRect.origin.y <= tableChatView.contentOffset.y
            if listViewOnSection.count != 0 && listViewOnSection.count - 1 == indexPath!.section && isPinned {
                let sect = listViewOnSection.count - 1 < currentIndexpath!.section ? listViewOnSection.count - 1 : currentIndexpath!.section
                let headerView = listViewOnSection[sect]
                headerView.isHidden = true
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
//        navigationController?.navigationBar.topItem?.title = ""
        Utils.addBackground(view: self.view)
        if let dataWall = UserDefaults.standard.data(forKey: "chatWallpaper") {
            wallpaperView.image = UIImage(data: UserDefaults.standard.data(forKey: "chatWallpaper")!)
        }
        else {
            wallpaperView.isHidden = true
        }
        if Nexilis.fromMAB {
            Nexilis.floatingButton.isHidden = true
        }
        
        viewButton.layer.shadowColor = self.traitCollection.userInterfaceStyle == .dark ? UIColor.white.cgColor : UIColor.gray.cgColor
        viewButton.layer.shadowOpacity = 1
        viewButton.layer.shadowOffset = .zero
        viewButton.layer.shadowRadius = 3
        viewButton.addTopBorder(with: UIColor.lightGray, andWidth: 1.0)
        
//        buttonVoice.setImage(resizeImage(image: UIImage(named: "Voice-Record", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)), for: .normal)
        viewAttachment.backgroundColor = .white
        buttonSendImage.setImage(resizeImage(image: UIImage(named: "Send-Image", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withTintColor(self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor), for: .normal)
        buttonSendPhoto.setImage(resizeImage(image: UIImage(named: "Camera", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withTintColor(self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor), for: .normal)
        buttonSendSticker.setImage(resizeImage(image: UIImage(named: "Sticker---Emoji", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withTintColor(self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor), for: .normal)
        buttonSendFile.setImage(resizeImage(image: UIImage(named: "File---Documents", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withTintColor(self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor), for: .normal)
        
        buttonSendChat.setImage(resizeImage(image: self.traitCollection.userInterfaceStyle == .dark ? UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(.blackDarkMode) : UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal), for: .normal)
        
        buttonSendChat.circle()
        buttonSendChat.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        buttonSendChat.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
        buttonAckConfidential.circle()
        buttonAckConfidential.addTarget(self, action: #selector(showChooserACKConfidential), for: .touchUpInside)
        buttonAckConfidential.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        buttonAckConfidential.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
        textFieldSend.backgroundColor = .white
        textFieldSend.layer.cornerRadius = textFieldSend.maxCornerRadius()
        textFieldSend.layer.borderWidth = 1.0
        textFieldSend.text = "Send message".localized()
        textFieldSend.textColor = UIColor.lightGray
        textFieldSend.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        textFieldSend.textContainerInset = UIEdgeInsets(top: 12, left: 20, bottom: 11, right: 40)
        textFieldSend.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        textFieldSend.font = UIFont.systemFont(ofSize: 12 + offset())
        textFieldSend.delegate = self
        textFieldSend.customDelegate = self
        textFieldSend.allowsEditingTextAttributes = true
        
        navigationItem.rightBarButtonItem?.tintColor = UIColor.secondaryColor
        
        imageVideoPicker = ImageVideoPicker(presentationController: self, delegate: self)
        documentPicker = DocumentPicker(presentationController: self, delegate: self)
        
        let fm = FileManager.default
        if Bundle.resourceBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif") != nil {
            let path = Bundle.resourceBundle(for: Nexilis.self).resourcePath! //resourcesMediaBundle
            let items = try! fm.contentsOfDirectory(atPath: path)
            
            for item in items {
                if item.hasPrefix("sticker") {
                    stickers.append(item)
                }
            }
        } else {
            let path = Bundle.resourcesMediaBundle(for: Nexilis.self).resourcePath! //resourcesMediaBundle
            let items = try! fm.contentsOfDirectory(atPath: path)
            
            for item in items {
                if item.hasPrefix("sticker") {
                    stickers.append(item)
                }
            }
        }
        
        tableChatView.register(UITableViewCell.self, forCellReuseIdentifier: "cellEditorGroup")
        
        loadData()
        setRightButtonItem()
        
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(onReceiveMessage(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerReceiveChat), object: nil)
        center.addObserver(self, selector: #selector(onStatusChat(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerStatusChat), object: nil)
        center.addObserver(self, selector: #selector(onUploadChat(notification:)), name: NSNotification.Name(rawValue: "onUploadChat"), object: nil)
        center.addObserver(self, selector: #selector(onMemberTopic(notification:)), name: NSNotification.Name(rawValue: "onMember"), object: nil)
        center.addObserver(self, selector: #selector(onGroup(notification:)), name: NSNotification.Name(rawValue: "onGroup"), object: nil)
        center.addObserver(self, selector: #selector(onMemberTopic(notification:)), name: NSNotification.Name(rawValue: "onTopic"), object: nil)
        center.addObserver(self, selector: #selector(onFailedSendMessage(notification:)), name: NSNotification.Name(rawValue: Nexilis.failedSendMessage), object: nil)
        center.addObserver(self, selector: #selector(onUpdatedMessage(notification:)), name: NSNotification.Name(rawValue: "onUpdatedMessage"), object: nil)
        center.addObserver(self, selector: #selector(onCheckNewMessages(notification:)), name: NSNotification.Name(rawValue: "checkNewMessagesNexilis"), object: nil)
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        DispatchQueue.global().async { [self] in
            if CLLocationManager.locationServicesEnabled() {
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.startUpdatingLocation()
            } else {
                print("Location services are not enabled.")
            }
        }
        
        if dataMessageForward != nil {
            for i in 0..<dataMessageForward!.count {
                let isForwarded = (dataMessageForward![i][TypeDataMessage.is_forwarded] as? Int) ?? 0
                sendChat(message_scope_id: MessageScope.GROUP, status: "2", message_text: dataMessageForward![i]["message_text"]  as? String ?? "", credential: "0", attachment_flag: dataMessageForward![i]["attachment_flag"]  as? String ?? "", ex_blog_id: "", message_large_text: "", ex_format: "", image_id: dataMessageForward![i]["image_id"]  as? String ?? "", audio_id: dataMessageForward![i]["audio_id"]  as? String ?? "", video_id: dataMessageForward![i]["video_id"]  as? String ?? "", file_id: dataMessageForward![i]["file_id"]  as? String ?? "", thumb_id: dataMessageForward![i]["thumb_id"]  as? String ?? "", reff_id: "", read_receipts: "", is_call_center: "0", call_center_id: "", viewController: self, gif_id: dataMessageForward![i][TypeDataMessage.gif_id]  as? String ?? "", is_forwarded: isForwarded + 1)
            }
            dataMessageForward = nil
        }
        tableMention.register(UITableViewCell.self, forCellReuseIdentifier: "cellMention")
        tableMention.dataSource = self
        tableMention.delegate = self
        tableMention.contentInset = UIEdgeInsets(top: -25, left: 0, bottom: 0, right: 0)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        latitude = "\(location.coordinate.latitude)"
        longitude = "\(location.coordinate.longitude)"
        locationManager.stopUpdatingLocation()
    }
    
    public func afterUnfriend() {
        DispatchQueue.main.async {
            SecureUserDefaults.shared.removeValue(forKey: "inEditorGroup")
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    private func updateProfile() {
        let idMe = User.getMyPin() as String?
        DispatchQueue.global().async {
            let message = CoreMessage_TMessageBank.getBatchBuddiesInfos(p_f_pin: idMe!, last_update: 0)
            let _ = Nexilis.write(message: message)
        }
    }
    
    private func setRightButtonItem() {
        navigationItem.rightBarButtonItems = nil
        navigationItem.rightBarButtonItem = nil
        let menu = UIMenu(title: "", children: [
            UIAction(title: "Delete Conversation".localized(), handler: {(_) in
                let alert = LibAlertController(title: "", message: "Are you sure to delete all message in this conversation?".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel".localized(), style: UIAlertAction.Style.default, handler: nil))
                alert.addAction(UIAlertAction(title: "Delete".localized(), style: .destructive, handler: {(_) in
                    var l_pin = self.dataGroup["group_id"]  as? String ?? ""
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            if (self.dataTopic["chat_id"]  as? String ?? "" != "") {
                                l_pin = self.dataTopic["chat_id"]  as? String ?? ""
                            }
                            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "(l_pin='\(self.dataGroup["group_id"]!!)' and chat_id='\(self.dataTopic["chat_id"]!!)') and message_scope_id='4'")
                            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "l_pin='\(l_pin)'")
                            SecureUserDefaults.shared.removeValue(forKey: "new_saved_\(l_pin)")
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                            if self.fromNotification {
                                self.didTapExit()
                            } else {
                                self.navigationController?.popViewController(animated: true)
                            }
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                }))
                self.present(alert, animated: true, completion: nil)
            }),
        ])
        if !isHistoryCC {
            let moreIcon = UIBarButtonItem(image: UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), menu: menu)
            let buttonSearch = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), style: .plain, target: self, action: #selector(search(sender:)))
            navigationItem.rightBarButtonItems = [moreIcon,buttonSearch]
        } else {
            let buttonSearch = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), style: .plain, target: self, action: #selector(search(sender:)))
            navigationItem.rightBarButtonItem = buttonSearch
        }
    }
    
    @objc func search(sender: UIBarButtonItem) {
        self.isSearching = true
        if self.reffId != nil {
            self.deleteReplyView()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
            cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
            if !self.isHistoryCC {
                self.navigationItem.rightBarButtonItems = nil
            }
            self.navigationItem.rightBarButtonItem = cancelButton
            self.changeAppBar()
            self.addMultipleSelectSession()
        }
    }
    
    private func getOfficialGroup() {
        let query = "SELECT group_id, f_name, official, image_id FROM GROUPZ where group_type = 1 AND official = 1"
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    if cursorData.next() {
                        dataGroup["group_id"] = cursorData.string(forColumnIndex: 0)
                        dataTopic["chat_id"] = ""
                        dataGroup["f_name"] = cursorData.string(forColumnIndex: 1)
                        dataGroup["image_id"] = cursorData.string(forColumnIndex: 3)
                        dataGroup["official"] = cursorData.string(forColumnIndex: 2)
                    }
                    cursorData.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    func loadData() {
        if (unique_l_pin != "") {
            dataDates.removeAll()
            dataGroup.removeAll()
            dataTopic.removeAll()
            dataMessages.removeAll()
            tableChatView.reloadData()
            currentIndexpath = nil
            reffId = nil
            getDataGroup(unique_l_pin: unique_l_pin)
        }
        
        if removed {
            removed = false
            containerActionGroup.removeConstraints(containerActionGroup.constraints)
            containerActionGroup.removeFromSuperview()
            setRightButtonItem()
        }
        
        if !isHistoryCC {
            let groupId = dataGroup["group_id"]  as? String ?? ""
            let chatId = dataTopic["chat_id"]  as? String ?? ""
            let dataGT: [String] = [groupId, chatId]
            SecureUserDefaults.shared.set(dataGT, forKey: "inEditorGroup")
            
            if dataTopic["chat_id"]  as? String ?? "" == "" {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [groupId])
                sendTyping(l_pin: groupId)
            } else {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [chatId])
                sendTyping(l_pin: chatId)
            }
        } else {
            getOfficialGroup()
            disableEditor()
        }
        
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
        
        changeAppBar()
        getData()
        getCounter()
        if counter > 0 && dataMessages.count >= counter {
            markerCounter = dataMessages[dataMessages.count - counter]["message_id"] as? String
        }
        
        tableChatView.alpha = 0
        tableChatView.delegate = self
        tableChatView.dataSource = self
        tableChatView.reloadData()
        if !referenceMessageId.isEmpty {
            if dataMessages.firstIndex(where: {$0["message_id"] as? String == referenceMessageId} ) != 0 {
                DispatchQueue.main.async {
                    let section = self.dataDates.firstIndex(of: self.referenceChatDate)
                    let row = self.dataMessages.filter({$0["chat_date"]  as? String ?? "" == self.referenceChatDate}).firstIndex(where: { $0["message_id"] as? String == self.referenceMessageId})
                    if row != nil && section != nil {
                        let indexPath = IndexPath(row: row!, section: section!)
                        self.tableChatView.scrollToRow(at: indexPath, at: .middle, animated: false)
                        self.tableChatView.cellForRow(at: indexPath)?.contentView.backgroundColor = .yellow
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                            self.tableChatView.cellForRow(at: indexPath)?.contentView.backgroundColor = .clear
                        })
                    }
                }
            }
        } else if counter != 0 {
            if dataMessages.firstIndex(where: {$0["message_id"] as? String == markerCounter} ) != 0 {
                DispatchQueue.main.async {
                    let data = self.dataMessages.filter({ $0["message_id"] as? String == self.markerCounter })
                    if data.count > 0 {
                        let section = self.dataDates.firstIndex(of: data[0]["chat_date"]  as? String ?? "")
                        let row = self.dataMessages.filter({$0["chat_date"]  as? String ?? "" == data[0]["chat_date"]  as? String ?? ""}).firstIndex(where: { $0["message_id"] as? String == self.markerCounter})
                        self.tableChatView.scrollToRow(at: IndexPath(row: row!, section: section!), at: .bottom, animated: false)
                    }
                }
            } else {
                tableChatView.scrollToTop()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                if currentIndexpath == nil && counter != 0 {
                    let idMe = User.getMyPin() as String?
                    if let idx = dataMessages.firstIndex(where: { $0["message_id"] as? String == markerCounter}) {
                        for i in idx..<dataMessages.count {
                            if dataMessages[i]["f_pin"] as? String != idMe {
                                sendReadMessageStatus(chat_id: self.dataTopic["chat_id"]  as? String ?? "", f_pin: dataMessages[i]["f_pin"]  as? String ?? "", message_scope_id: MessageScope.GROUP, message_id: dataMessages[i]["message_id"]  as? String ?? "")
                            }
                        }
                        counter = 0
                        updateCounter(counter: counter)
                    }
                }
            }
        } else {
            var l_pin = self.dataGroup["group_id"]  as? String ?? ""
            if (self.dataTopic["chat_id"]  as? String ?? "" != "") {
                l_pin = self.dataTopic["chat_id"]  as? String ?? ""
            }
            if let dataSaved: String = SecureUserDefaults.shared.value(forKey: "new_saved_\(l_pin)") {
                let data = dataSaved
                if let jsonData = data.data(using: .utf8),
                   let dataJson = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    let last_m = dataJson["text"] as? String ?? ""
                    let last_r = dataJson["reffId"] as? String ?? ""
                    let list_m = dataJson["list_mention"] as? [[String: String]] ?? []
                    
                    if !last_m.isEmpty {
                        textFieldSend.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black
                    }
                    
                    if list_m.count > 0 {
                        for list in list_m {
                            let f_pin = list["f_pin_mention"] ?? ""
                            let upper = list["upper"] ?? ""
                            let userFromBuddy = User.getData(pin: f_pin, lPin: l_pin)
                            if userFromBuddy != nil {
                                userFromBuddy!.ex_block = upper
                                listMentionInTextField.append(userFromBuddy!)
                            }
                        }
                    }
                    
                    if !last_m.isEmpty {
                        textFieldSend.attributedText = last_m.richText(isEditing: true, group_id: self.dataGroup["group_id"]  as? String ?? "", listMentionInTextField: listMentionInTextField)
                    }
                    
                    if !last_r.isEmpty {
                        handleReply(indexPath: IndexPath(row: 0, section: 0), reffId: last_r)
                    }
                }
            }
            tableChatView.scrollToBottom(isAnimated: false)
        }
        tableChatView.keyboardDismissMode = .interactive
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableChatView.addGestureRecognizer(tapGesture)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
            if self.tableChatView.alpha != 1.0 {
                UIView.animate(withDuration: 0.5, animations: {
                    self.tableChatView.alpha = 1.0
                })
            }
        })
        for data in listTimerCredential {
            if data.value > 0 {
                var second = data.value
                var timer = Timer()
                timerCredential[data.key] = timer
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {_ in
                    second -= 1
                    self.listTimerCredential[data.key] = second
                    let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == data.key })
                    if (idx != nil) {
                        let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
                        let row = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataMessages[idx!]["chat_date"]  as? String ?? ""}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                        if second == 0 {
                            timer.invalidate()
                            self.listTimerCredential.removeValue(forKey: data.key)
                            self.timerCredential.removeValue(forKey: data.key)
                            SecureUserDefaults.shared.removeValue(forKey: data.key)
                            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == data.key})
                            if idx != nil {
                                self.dataMessages[idx!]["lock"] = "2"
                                self.dataMessages[idx!]["reff_id"] = ""
                            }
                            DispatchQueue.global().async {
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                            "lock" : "2"
                                        ], _where: "message_id = '\(data.key)'")
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                            }
                        }
                        if row != nil && section != nil  {
                            self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                        }
                    }
                })
            }
        }
        let dataMessagesPin = self.dataMessages.filter({ $0[TypeDataMessage.is_pinned] as? String ?? "0" != "0"})
        pinAllMessages(dataMessages: dataMessagesPin)
    }
    
    func getDataProfile(f_pin: String, message_id: String) -> [String: String]{
        var data: [String: String] = [:]
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || last_name, image_id from BUDDY where f_pin = '\(f_pin)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0)!.trimmingCharacters(in: .whitespacesAndNewlines)
                data["image_id"] = c.string(forColumnIndex: 1) ?? ""
                c.close()
            }
            else if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || last_name, thumb_id from GROUPZ_MEMBER where f_pin = '\(f_pin)' AND group_id = '\(dataGroup["group_id"]!!)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0)!.trimmingCharacters(in: .whitespacesAndNewlines)
                data["image_id"] = c.string(forColumnIndex: 1) ?? ""
                c.close()
            } else if let c = Database().getRecords(fmdb: fmdb, query: "select f_display_name from MESSAGE where message_id = '\(message_id)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0) ?? ""
                data["image_id"] = ""
                c.close()
            } else if f_pin == "-997" {
                data["name"] = Utils.getGPTBotName()
                data["image_id"] = ""
            } else {
                data["name"] = "Unknown".localized()
            }
        })
        return data
    }
    
    private func getDataGroup(unique_l_pin: String) {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorGroup = Database.shared.getRecords(fmdb: fmdb, query: "SELECT group_id, f_name, image_id, official, parent FROM GROUPZ WHERE group_id='\(unique_l_pin)'"), cursorGroup.next() {
                    dataGroup["group_id"] = cursorGroup.string(forColumnIndex: 0)
                    dataGroup["f_name"] = cursorGroup.string(forColumnIndex: 1)
                    dataGroup["image_id"] = cursorGroup.string(forColumnIndex: 2)
                    dataGroup["official"] = cursorGroup.string(forColumnIndex: 3)
                    dataGroup["parent"] = cursorGroup.string(forColumnIndex: 4)
                    dataTopic["title"] = "Lounge".localized()
                    dataTopic["chat_id"] = ""
                    cursorGroup.close()
                } else if let cursorTopic = Database.shared.getRecords(fmdb: fmdb, query: "SELECT group_id, title FROM DISCUSSION_FORUM where chat_id = '\(unique_l_pin)'"), cursorTopic.next() {
                    dataGroup["group_id"] = cursorTopic.string(forColumnIndex: 0)
                    dataTopic["title"] = cursorTopic.string(forColumnIndex: 1)
                    dataTopic["chat_id"] = unique_l_pin
                    cursorTopic.close()
                    if let cursorGroup = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_name, image_id, official, parent FROM GROUPZ where group_id = '\(dataGroup["group_id"]  as? String ?? "")'"), cursorGroup.next() {
                        dataGroup["f_name"] = cursorGroup.string(forColumnIndex: 0)
                        dataGroup["image_id"] = cursorGroup.string(forColumnIndex: 1)
                        dataGroup["official"] = cursorGroup.string(forColumnIndex: 2)
                        dataGroup["parent"] = cursorGroup.string(forColumnIndex: 3)
                        cursorGroup.close()
                    }
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    private func getData(offset: Int64 = 0) {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                var query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared, blog_id, credential, last_edited, gif_id, is_forwarded_message, attachment_speciality, is_pinned FROM MESSAGE where chat_id='' AND l_pin='\(dataGroup["group_id"]  as? String ?? "")' order by server_date asc LIMIT -1 OFFSET \(offset)"
                if isHistoryCC {
                    query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared FROM MESSAGE where call_center_id='\(complaintId)' order by server_date asc LIMIT -1 OFFSET \(offset)"
                } else if (dataTopic["chat_id"]  as? String ?? "" != "") {
                    query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared, blog_id, credential, last_edited, gif_id, is_forwarded_message, attachment_speciality, is_pinned FROM MESSAGE where chat_id='\(dataTopic["chat_id"]  as? String ?? "")' order by server_date asc LIMIT -1 OFFSET \(offset)"
                }
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    var tempImages: [ImageGrouping] = []
                    var idxOff = 0
                    while cursorData.next() {
                        var row: [String: Any?] = [:]
                        row["message_id"] = cursorData.string(forColumnIndex: 0)
                        row["f_pin"] = cursorData.string(forColumnIndex: 1)
                        row["l_pin"] = cursorData.string(forColumnIndex: 2)
                        row["message_scope_id"] = cursorData.string(forColumnIndex: 3)
                        row["server_date"] = cursorData.string(forColumnIndex: 4)
                        row["status"] = cursorData.string(forColumnIndex: 5)
                        row["message_text"] = cursorData.string(forColumnIndex: 6)
                        row["audio_id"] = cursorData.string(forColumnIndex: 7)
                        row["video_id"] = cursorData.string(forColumnIndex: 8)
                        row["image_id"] = cursorData.string(forColumnIndex: 9)
                        row["thumb_id"] = cursorData.string(forColumnIndex: 10)
                        row["read_receipts"] = cursorData.string(forColumnIndex: 11)
                        row["chat_id"] = cursorData.string(forColumnIndex: 12)
                        row["file_id"] = cursorData.string(forColumnIndex: 13)
                        row["attachment_flag"] = cursorData.string(forColumnIndex: 14)
                        row["reff_id"] = cursorData.string(forColumnIndex: 15)
                        row["lock"] = cursorData.string(forColumnIndex: 16)
                        row["is_stared"] = cursorData.string(forColumnIndex: 17)
                        row["blog_id"] = cursorData.string(forColumnIndex: 18) ?? ""
                        row["credential"] = cursorData.string(forColumnIndex: 19) ?? ""
                        row[TypeDataMessage.last_edit] = cursorData.longLongInt(forColumnIndex: 20)
                        row[TypeDataMessage.gif_id] = cursorData.string(forColumnIndex: 21) ?? ""
                        row[TypeDataMessage.is_forwarded] = Int(cursorData.int(forColumnIndex: 22))
                        row[TypeDataMessage.spec_file] = cursorData.string(forColumnIndex: 23) ?? ""
                        row[TypeDataMessage.is_pinned] = cursorData.string(forColumnIndex: 24) ?? ""
                        row["isSelected"] = false
                        if row["credential"] != nil && row["credential"]  as? String ?? "" == "1" {
                            let idMe = User.getMyPin()!
                            if row["f_pin"]  as? String ?? "" == idMe {
                                let second = getSecondsDifferenceFromTwoDates(start: Date.init(milliseconds: Int64(row["server_date"]  as? String ?? "")!), end: Date())
                                if second > 60 {
                                    listTimerCredential[row["message_id"]  as? String ?? ""] = 0
                                    row["lock"] = "2"
                                    row["reff_id"] = ""
                                    DispatchQueue.global().async {
                                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                            do {
                                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                                    "lock" : "2"
                                                ], _where: "message_id = '\(row["message_id"]  as? String ?? "")'")
                                            } catch {
                                                rollback.pointee = true
                                                print("Access database error: \(error.localizedDescription)")
                                            }
                                        })
                                    }
                                } else {
                                    let second = 60 - second
                                    listTimerCredential[row["message_id"]  as? String ?? ""] = second
                                }
                            } else {
                                let hasMessageId: String? = SecureUserDefaults.shared.value(forKey: row["message_id"]  as? String ?? "") ?? nil
                                if hasMessageId != nil {
                                    let second = getSecondsDifferenceFromTwoDates(start: Date.init(milliseconds: Int64(hasMessageId!)!), end: Date())
                                    if second > 60 {
                                        listTimerCredential[row["message_id"]  as? String ?? ""] = 0
                                        row["lock"] = "2"
                                        row["reff_id"] = ""
                                        DispatchQueue.global().async {
                                            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                                do {
                                                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                                        "lock" : "2"
                                                    ], _where: "message_id = '\(row["message_id"]  as? String ?? "")'")
                                                } catch {
                                                    rollback.pointee = true
                                                    print("Access database error: \(error.localizedDescription)")
                                                }
                                            })
                                        }
                                    } else {
                                        let second = 60 - second
                                        listTimerCredential[row["message_id"]  as? String ?? ""] = second
                                    }
                                } else {
                                    SecureUserDefaults.shared.set("\(Date().currentTimeMillis())", forKey: row["message_id"]  as? String ?? "")
                                    listTimerCredential[row["message_id"]  as? String ?? ""] = 60
                                }
                            }
                        }
                        row[TypeDataMessage.is_call_center] = cursorData.string(forColumnIndex: 20)
                        row[TypeDataMessage.call_center_id] = cursorData.string(forColumnIndex: 21)
                        row[TypeDataMessage.opposite_pin] = cursorData.string(forColumnIndex: 22)
                        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                        if let dirPath = paths.first {
                            let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["video_id"]  as? String ?? "")
                            let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["file_id"]  as? String ?? "")
                            if ((row["video_id"]  as? String ?? "") != "") {
                                if FileManager.default.fileExists(atPath: videoURL.path) || FileEncryption.shared.isSecureExists(filename: row["video_id"]  as? String ?? ""){
                                    row["progress"] = 100.0
                                } else {
                                    row["progress"] = 0.0
                                }
                            } else {
                                if FileManager.default.fileExists(atPath: fileURL.path) || FileEncryption.shared.isSecureExists(filename: row["file_id"]  as? String ?? ""){
                                    row["progress"] = 100.0
                                } else {
                                    row["progress"] = 0.0
                                }
                            }
                        }
                        row["chat_date"] = chatDate(stringDate: row["server_date"]  as? String ?? "")
                        
                        if (dataMessages.count == 0 || dataMessages.last!["f_pin"]  as? String ?? "" == row["f_pin"]  as? String ?? "") && tempImages.count <= 30 && row["image_id"] != nil && !(row["image_id"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (row["message_text"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (row["reff_id"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (row["read_receipts"] as? String ?? "") != "8" {
                            if tempImages.count != 0 && getSecondsDifferenceFromTwoDates(start: Date.init(milliseconds: Int64(tempImages.last!.time)!), end: Date.init(milliseconds: Int64(row["server_date"]  as? String ?? "")!))/60 >= 11 {
                                if tempImages.count >= 4 {
                                    groupImages[tempImages[0].messageId] = tempImages
                                    if let idxTemp = dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == tempImages[0].messageId }) {
                                        for _ in 1..<tempImages.count {
                                            dataMessages.remove(at: idxTemp + 1)
                                        }
                                    }
                                }
                                tempImages.removeAll()
                            }
                            tempImages.append(ImageGrouping(messageId: row["message_id"]  as? String ?? "", thumbId: row["thumb_id"]  as? String ?? "", imageId: row["image_id"]  as? String ?? "", status: row["status"]  as? String ?? "", time: row["server_date"]  as? String ?? "", lPin: row["l_pin"]  as? String ?? "", dataMessage: row, dataPerson: [:], dataGroup: dataGroup, dataTopic: dataTopic))
                        } else if tempImages.count >= 4 {
                            groupImages[tempImages[0].messageId] = tempImages
                            if let idxTemp = dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == tempImages[0].messageId }) {
                                for _ in 1..<tempImages.count {
                                    dataMessages.remove(at: idxTemp + 1)
                                }
                            }
                            tempImages.removeAll()
                        } else if tempImages.count != 0 {
                            tempImages.removeAll()
                        }
                        if offset > 0 && idxOff == 0 {
                            self.markerCounter = row["message_id"] as? String
                        }
                        dataMessages.append(row)
                        idxOff+=1
                    }
    //                if isHistoryCC {
    //                    dataMessages.remove(at: 0)
    //                }
                    if tempImages.count >= 4 {
                        if tempImages.count > 30 {
                            tempImages.removeSubrange(30..<tempImages.count)
                        }
                        groupImages[tempImages[0].messageId] = tempImages
                        if let idxTemp = dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == tempImages[0].messageId }) {
                            for _ in 1..<tempImages.count {
                                dataMessages.remove(at: idxTemp + 1)
                            }
                        }
                    }
                    cursorData.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    func getSecondsDifferenceFromTwoDates(start: Date, end: Date) -> Int {
        let diff = Int(end.timeIntervalSince1970 - start.timeIntervalSince1970)

        let hours = diff / 3600
        let seconds = (diff - hours * 3600)
        return seconds
    }
    
    private func getRealStatus(messageId: String) -> String {
        var status = "-1"
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorStatus = Database.shared.getRecords(fmdb: fmdb, query: "SELECT status, f_pin FROM MESSAGE_STATUS WHERE message_id='\(messageId)'") {
                    var listStatus: [Int] = []
                    while cursorStatus.next() {
                        listStatus.append(Int(cursorStatus.string(forColumnIndex: 0)!)!)
                    }
                    cursorStatus.close()
                    status = "\(listStatus.min() ?? -1)"
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        return status
    }
    
    private func chatDate(stringDate: String) -> String {
        let date = Date(milliseconds: Int64(stringDate)!)
        let calendar = Calendar.current
        if (calendar.isDateInToday(date)) {
            if !dataDates.contains("Today".localized()){
                dataDates.append("Today".localized())
            }
            return "Today".localized()
        } else {
            let startOfNow = calendar.startOfDay(for: Date())
            let startOfTimeStamp = calendar.startOfDay(for: date)
            let components = calendar.dateComponents([.day], from: startOfNow, to: startOfTimeStamp)
            let day = -(components.day!)
            if day == 1{
                if !dataDates.contains("Yesterday".localized()){
                    dataDates.append("Yesterday".localized())
                }
                return "Yesterday".localized()
            } else if day < 7 {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
                if lang == "id" {
                    formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                }
                if !dataDates.contains(formatter.string(from: date)){
                    dataDates.append(formatter.string(from: date))
                }
                return formatter.string(from: date)
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "EE, dd MMM"
                let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
                if lang == "id" {
                    formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                }
                let stringFormat = formatter.string(from: date as Date)
                if !dataDates.contains(stringFormat){
                    dataDates.append(stringFormat)
                }
                return stringFormat
            }
        }
    }
    
    private func changeAppBar() {
        let viewAppBar = UIView()
        viewAppBar.frame.size = CGSize(width: self.view.frame.size.width, height: 44)
        
        if !isSearching {
            let imageProfile = UIImageView(frame: CGRect(x: 0, y: 7, width: 30, height: 30))
            imageProfile.circle()
            imageProfile.clipsToBounds = true
            viewAppBar.addSubview(imageProfile)
            let pictureImage = dataGroup["image_id"] ?? ""
            if (pictureImage  as? String ?? "" != "" && pictureImage != nil) {
                imageProfile.setImage(name: pictureImage!  as? String ?? "")
                imageProfile.contentMode = .scaleAspectFill
            } else {
                imageProfile.image = UIImage(systemName: "person.3")
                imageProfile.contentMode = .scaleAspectFit
                imageProfile.backgroundColor = .lightGray
            }
            var widthTitle = viewAppBar.frame.size.width - 180
            if isHistoryCC {
                widthTitle = viewAppBar.frame.size.width - 150
            }
            let titleNavigation = UILabel(frame: CGRect(x: 35, y: 0, width: widthTitle, height: 44))
            viewAppBar.addSubview(titleNavigation)
            if (dataGroup["official"]  as? String ?? "" == "1") {
                if !isHistoryCC {
                    titleNavigation.set(image: UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(dataGroup["f_name"]!!) (\(dataTopic["title"]!!))", size: 15, y: -4)
                } else {
                    titleNavigation.text = (dataGroup["f_name"] as? String)! + " " + "Contact Center".localized()
                }
            } else {
                titleNavigation.text = (dataGroup["f_name"] as? String ?? "") + " (\(dataTopic["title"] as? String ?? ""))"
            }
            titleNavigation.textColor = .white
            titleNavigation.font = UIFont.systemFont(ofSize: 12 + offset()).bold
            
            navigationItem.titleView = viewAppBar
            titleText = titleNavigation.text
        } else {
            searchBar = UISearchBar()
            searchBar.autocapitalizationType = .none
            searchBar.delegate = self
            searchBar.searchTextField.tintColor = .mainColor
            searchBar.searchTextField.textColor = .mainColor
//            searchBar.updateHeight(height: 36, radius: 18)
            searchBar.showsCancelButton = false
//            searchBar.setMagnifyingGlassColorTo(color: .white)
            searchBar.setImage(UIImage(), for: .search, state: .normal)
            searchBar.setPositionAdjustment(UIOffset(horizontal: 10, vertical: 0), for: .search)
            searchBar.setCustomBackgroundImage(image: UIImage(named: self.traitCollection.userInterfaceStyle == .dark ? "nx_search_bar_dark" : "nx_search_bar", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
            navigationItem.titleView = searchBar
            self.definesPresentationContext = true
        }
        
        if copySession || forwardSession || deleteSession || isSearching {
            navigationItem.hidesBackButton = true
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        } else {
            navigationItem.hidesBackButton = false
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
        
        viewAppBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(seeProfileTapped)))
    }
    
    func updateProgress(_ data: [AnyHashable: Any]){
        var isImage = false
        var idx = dataMessages.lastIndex(where: { $0["video_id"]  as? String ?? "" == data["name"]  as? String ?? "" || $0["video_id"] as? String == data["video_id"] as? String })
        if (idx == nil) {
            idx = dataMessages.lastIndex(where: { $0["image_id"]  as? String ?? "" == data["name"]  as? String ?? "" || $0["image_id"] as? String == data["image_id"] as? String })
            isImage = true
        }
        if (idx != nil) {
            let section = dataDates.firstIndex(of: dataMessages[idx!]["chat_date"]  as? String ?? "")
            if section == nil {
                return
            }
            let row = dataMessages.filter({ $0["chat_date"]  as? String ?? "" == dataDates[section!]}).firstIndex(where: { $0["message_id"]  as? String ?? "" == dataMessages[idx!]["message_id"]  as? String ?? ""})
            if row == nil {
                return
            }
            DispatchQueue.main.async {
                let indexPath = IndexPath(row: row!, section: section!)
                if(self.fakeProgMultip < self.maxFakeProgMultip){
                    self.fakeProgMultip = self.fakeProgMultip + 1
                }
                let fakeProgress = Double(self.fakeProgMultip) * (100.0 / Double(self.maxFakeProgMultip))
                let progress = max(data["progress"] as! Double, fakeProgress)
                if(data["progress"] as! Double == 100.0){
                    self.fakeProgMultip = 0
                }
                if let cell = self.tableChatView.cellForRow(at: indexPath) {
                    for view in cell.contentView.subviews {
                        if !(view is UITextView) && !(view is UIImageView) {
                            for viewInContainer in view.subviews {
                                if viewInContainer is UIImageView {
                                    if viewInContainer.subviews.count == 0 {
                                        return
                                    }
                                    var containerView : UIView?
                                    if (isImage) {
                                        containerView = viewInContainer.subviews[0]
                                    } else if viewInContainer.subviews.count > 1 {
                                        containerView = viewInContainer.subviews[1]
                                    }
                                    if let loading = containerView?.layer.sublayers?[1] as? CAShapeLayer {
                                        loading.strokeEnd = CGFloat(progress / 100)
                                        if (progress == 100.0) {
                                            self.dataMessages[idx!]["progress"] = progress
                                            self.tableChatView.reloadRows(at: [indexPath], with: .none)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            idx = dataMessages.lastIndex(where: { $0["file_id"]  as? String ?? "" == data["name"]  as? String ?? "" || $0["file_id"] as? String == data["file_id"] as? String })
            if (idx != nil) {
                DispatchQueue.main.async {
                    let section = 0
                    let indexPath = IndexPath(row: idx!, section: section)
                    if(self.fakeProgMultip < self.maxFakeProgMultip){
                        self.fakeProgMultip = self.fakeProgMultip + 1
                    }
                    let fakeProgress = Double(self.fakeProgMultip) * (100.0 / Double(self.maxFakeProgMultip))
                    let progress = max(data["progress"] as! Double, fakeProgress)
                    if(data["progress"] as! Double == 100.0){
                        self.fakeProgMultip = 0
                    }
                    if let cell = self.tableChatView.cellForRow(at: indexPath) {
                        for view in cell.contentView.subviews {
                            if !(view is UITextView) && !(view is UIImageView) {
                                for viewSubviews in view.subviews {
                                    if !(viewSubviews is UITextView) {
                                        for viewInContainer in viewSubviews.subviews {
                                            if !(viewInContainer is UITextView) && !(viewInContainer is UIImageView) {
                                                if let cont = viewInContainer.layer.sublayers {
                                                    if cont.count < 2 {
                                                        return
                                                    }
                                                }
                                                if let layers = viewInContainer.layer.sublayers {
                                                    if let loading = layers [1] as? CAShapeLayer {
                                                        loading.strokeEnd = CGFloat(progress / 100)
                                                        if (progress == 100.0) {
                                                            self.dataMessages[idx!]["progress"] = progress
                                                            self.tableChatView.reloadRows(at: [indexPath], with: .none)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func onUploadChat(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        updateProgress(data)
    }
    
    @objc func  onCheckNewMessages(notification: NSNotification) {
        var query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared, blog_id, credential, last_edited, gif_id, is_forwarded_message, attachment_speciality, is_pinned FROM MESSAGE where chat_id='' AND l_pin='\(dataGroup["group_id"]  as? String ?? "")' order by server_date asc"
        if isHistoryCC {
            query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared FROM MESSAGE where call_center_id='\(complaintId)' order by server_date asc"
        } else if (dataTopic["chat_id"]  as? String ?? "" != "") {
            query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared, blog_id, credential, last_edited, gif_id, is_forwarded_message, attachment_speciality, is_pinned FROM MESSAGE where chat_id='\(dataTopic["chat_id"]  as? String ?? "")' order by server_date asc"
        }
        var countMessagesNow: Int64 = 0
        DispatchQueue.main.async { [self] in
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    if let cursorCount = Database.shared.getRecords(fmdb: fmdb, query: query), cursorCount.next() {
                        countMessagesNow = Int64(cursorCount.int(forColumnIndex: 0))
                        cursorCount.close()
                    }
                }catch{}
            })
            if dataMessages.count < countMessagesNow {
                self.counter = Int(countMessagesNow) - dataMessages.count
                getData(offset: Int64(self.dataMessages.count))
                tableChatView.reloadData()
                if !self.indicatorCounterBSTB.isDescendant(of: self.view) && !self.buttonScrollToBottom.isDescendant(of: self.view) {
                    let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.markerCounter })
                    if indexMessage != nil {
                        let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"]  as? String ?? "")
                        let row = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataMessages[indexMessage!]["chat_date"]  as? String ?? ""}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                        self.tableChatView.scrollToRow(at: IndexPath(row: row!, section: section!), at: .top, animated: true)
                    }
                } else if self.buttonScrollToBottom.isDescendant(of: self.view) {
                    if !self.indicatorCounterBSTB.isDescendant(of: self.view) {
                        addCounterAtButttonScrollToBottom()
                    } else {
                        self.labelCounter.text = "\(counter)"
                    }
                } else {
                    addButtonScrollToBottom()
                    addCounterAtButttonScrollToBottom()
                }
            }
        }
    }
    
    @objc func onUpdatedMessage(notification: NSNotification) {
        DispatchQueue.main.async {
            let data:[AnyHashable : Any] = notification.userInfo!
            let messageId = data["message_id"]  as? String ?? ""
            let messageIdNotif = data["message_id_notif"]  as? String ?? ""
            let isPinned = data["is_pinned"]  as? String ?? ""
            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String ?? "" == messageId})
            if idx != nil{
                self.dataMessages[idx!][TypeDataMessage.is_pinned] = isPinned
                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
                let row = self.dataMessages.filter({ $0["chat_date"] as? String ?? "" == self.dataMessages[idx!]["chat_date"]  as? String ?? ""}).firstIndex(where: { $0["message_id"]  as? String ?? "" == self.dataMessages[idx!]["message_id"]  as? String ?? "" })
                if row != nil && section != nil  {
                    DispatchQueue.main.async {
                        self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                    }
                }
                let dataMessagesPin = self.dataMessages.filter({ $0[TypeDataMessage.is_pinned] as? String ?? "0" != "0"})
                self.pinAllMessages(dataMessages: dataMessagesPin)
                
                if !messageIdNotif.isEmpty {
                    self.appendNewMessage(messageId: messageIdNotif)
                }
            }
        }
    }
    
    @objc func onReceiveMessage(notification: NSNotification) {
        DispatchQueue.main.async {
            let data:[AnyHashable : Any] = notification.userInfo!
            if let dataMessage = data["message"] as? TMessage {
                let chatData = dataMessage.mBodies
                let group_id = self.dataGroup["group_id"]  as? String ?? ""
                let chat_id = self.dataTopic["chat_id"]  as? String ?? ""
                if chatData[CoreMessage_TMessageKey.L_PIN] == group_id && (chatData[CoreMessage_TMessageKey.CHAT_ID] ?? "") == chat_id {
                    let idx = self.dataMessages.firstIndex(where: { $0[TypeDataMessage.message_id] as? String == chatData[CoreMessage_TMessageKey.MESSAGE_ID]})
                    if idx != nil {
                        self.dataMessages[idx!][TypeDataMessage.message_text] = chatData[CoreMessage_TMessageKey.MESSAGE_TEXT]
                        self.dataMessages[idx!][TypeDataMessage.last_edit] = Int64(chatData[CoreMessage_TMessageKey.LAST_EDIT]!)
                        self.dataMessages[idx!][TypeDataMessage.status] = chatData[CoreMessage_TMessageKey.STATUS]
                        let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
                        let row = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataMessages[idx!]["chat_date"]  as? String ?? ""}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                        if row != nil && section != nil  {
                            self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                        }
                        return
                    }
                    var row: [String: Any?] = [:]
                    row["message_id"] = chatData[CoreMessage_TMessageKey.MESSAGE_ID]
                    row["f_pin"] = chatData[CoreMessage_TMessageKey.F_PIN]
                    row["l_pin"] = chatData[CoreMessage_TMessageKey.L_PIN]
                    row["message_scope_id"] = chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]
                    row["server_date"] = chatData[CoreMessage_TMessageKey.SERVER_DATE]
                    row["status"] = chatData[CoreMessage_TMessageKey.STATUS]
                    row["message_text"] = chatData[CoreMessage_TMessageKey.MESSAGE_TEXT]
                    if (chatData.keys.contains(CoreMessage_TMessageKey.AUDIO_ID)) {
                        row["audio_id"] = chatData[CoreMessage_TMessageKey.AUDIO_ID]
                    } else {
                        row["audio_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.GIF_ID)) {
                        row["gif_id"] = chatData[CoreMessage_TMessageKey.GIF_ID]
                    } else {
                        row["gif_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.VIDEO_ID)) {
                        row["video_id"] = chatData[CoreMessage_TMessageKey.VIDEO_ID]
                    } else {
                        row["video_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.IMAGE_ID)) {
                        row["image_id"] = chatData[CoreMessage_TMessageKey.IMAGE_ID]
                    } else {
                        row["image_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.THUMB_ID)) {
                        row["thumb_id"] = chatData[CoreMessage_TMessageKey.THUMB_ID]
                    } else {
                        row["thumb_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.CHAT_ID)) {
                        row["chat_id"] = chatData[CoreMessage_TMessageKey.CHAT_ID]
                    } else {
                        row["chat_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.FILE_ID)) {
                        row["file_id"] = chatData[CoreMessage_TMessageKey.FILE_ID]
                    } else {
                        row["file_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.READ_RECEIPTS)) {
                        row["read_receipts"] = chatData[CoreMessage_TMessageKey.READ_RECEIPTS]
                    } else {
                        row["read_receipts"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.CREDENTIAL)) {
                        row["credential"] = chatData[CoreMessage_TMessageKey.CREDENTIAL]
                    } else {
                        row["credential"] = ""
                    }
                    row["progress"] = 0.0
                    row["attachment_flag"] = chatData[CoreMessage_TMessageKey.ATTACHMENT_FLAG]
                    row["reff_id"] = chatData[CoreMessage_TMessageKey.REF_ID] ?? ""
                    row["lock"] = ""
                    row["is_stared"] = "0"
                    row[TypeDataMessage.is_forwarded] = Int(chatData[CoreMessage_TMessageKey.IS_FORWARDED_MESSAGE] ?? "0")
                    row[TypeDataMessage.spec_file] = chatData[CoreMessage_TMessageKey.ATTACHMENT_SPECIALITY]
                    row["isSelected"] = false
                    if !self.dataDates.contains("Today".localized()){
                        self.dataDates.append("Today".localized())
                        self.tableChatView.insertSections(IndexSet(integer: self.dataDates.count - 1), with: .fade)
                    }
                    row["chat_date"] = "Today".localized()
                    row["blog_id"] = chatData[CoreMessage_TMessageKey.BLOG_ID]
                    if row["credential"] != nil && row["credential"]  as? String ?? "" == "1" {
                        self.listTimerCredential[row["message_id"]  as? String ?? ""] = 60
                    }
                    self.counter += 1
                    self.tableChatView.beginUpdates()
                    self.dataMessages.append(row)
                    self.tableChatView.insertRows(at: [IndexPath(row: self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataDates[self.dataDates.count - 1]}).count - 1, section: self.dataDates.count - 1)], with: .fade)
                    self.tableChatView.endUpdates()
                    if row["credential"] != nil && row["credential"]  as? String ?? "" == "1" {
                        var timer = Timer()
                        var minute = 60
                        self.timerCredential[row["message_id"]  as? String ?? ""] = timer
                        SecureUserDefaults.shared.set("\(Date().currentTimeMillis())", forKey: row["message_id"]  as? String ?? "")
                        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {_ in
                            minute -= 1
                            self.listTimerCredential[row["message_id"]  as? String ?? ""] = minute
                            if minute == 0 {
                                timer.invalidate()
                                self.listTimerCredential.removeValue(forKey: row["message_id"]  as? String ?? "")
                                self.timerCredential.removeValue(forKey: row["message_id"]  as? String ?? "")
                                SecureUserDefaults.shared.removeValue(forKey: row["message_id"]  as? String ?? "")
                                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == row["message_id"] as? String})
                                if idx != nil {
                                    self.dataMessages[idx!]["lock"] = "2"
                                    self.dataMessages[idx!]["reff_id"] = ""
                                }
                                DispatchQueue.global().async {
                                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                        do {
                                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                                "lock" : "2"
                                            ], _where: "message_id = '\(row["message_id"]  as? String ?? "")'")
                                        } catch {
                                            rollback.pointee = true
                                            print("Access database error: \(error.localizedDescription)")
                                        }
                                    })
                                }
                            }
                            let section = self.dataDates.firstIndex(of: self.dataDates[self.dataDates.count - 1])
                            let row = self.dataMessages.filter({$0["chat_date"]  as? String ?? "" == self.dataDates[self.dataDates.count - 1]}).firstIndex(where: { $0["message_id"] as? String == row["message_id"] as? String})
                            let indexPath = IndexPath(row: row!, section: section!)
                            if row != nil && section != nil{
                                self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                            }
                        })
                    }
                    if  self.currentIndexpath?.row == (self.dataMessages.count - 2) {
                        if (self.viewIfLoaded?.window != nil) {
                            self.sendReadMessageStatus(chat_id: self.dataTopic["chat_id"]  as? String ?? "", f_pin: chatData[CoreMessage_TMessageKey.F_PIN]!, message_scope_id: chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]!, message_id: chatData[CoreMessage_TMessageKey.MESSAGE_ID]!)
                        }
                        self.tableChatView.scrollToBottom()
                        if (self.currentIndexpath!.section <= self.dataDates.count - 1 && self.currentIndexpath!.row <= self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataDates[self.dataDates.count - 1]}).count - 1)  {
                            self.counter = 0
                            self.updateCounter(counter: self.counter)
                        }
                        let lastMarkerCounter = self.markerCounter
                        if self.markerCounter != nil {
                            self.markerCounter = nil
                        }
                        let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == lastMarkerCounter })
                        if indexMessage != nil {
                            let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"]  as? String ?? "")
                            let row = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataMessages[indexMessage!]["chat_date"]  as? String ?? ""}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                            if row != nil && section != nil  {
                                self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                            }
                        }
                    }
                    else if self.currentIndexpath == nil {
                        self.counter = 0
                        self.updateCounter(counter: self.counter)
                        if (self.viewIfLoaded?.window != nil) {
                            self.sendReadMessageStatus(chat_id: self.dataTopic["chat_id"]  as? String ?? "", f_pin: chatData[CoreMessage_TMessageKey.F_PIN]!, message_scope_id: chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]!, message_id: chatData[CoreMessage_TMessageKey.MESSAGE_ID]!)
                        }
                    }
                    else if self.counter != 0 {
                        if !self.indicatorCounterBSTB.isDescendant(of: self.view) && self.buttonScrollToBottom.isDescendant(of: self.view) {
                            self.markerCounter = row["message_id"] as? String
                            self.addCounterAtButttonScrollToBottom()
                            let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.markerCounter })
                            if indexMessage != nil {
                                let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"]  as? String ?? "")
                                let row = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataMessages[indexMessage!]["chat_date"]  as? String ?? ""}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                                if row != nil && section != nil  {
                                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                }
                            }
                        } else if self.indicatorCounterBSTB.isDescendant(of: self.view) {
                            self.labelCounter.text = "\(self.counter)"
                        }
                    }
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                }
            } else {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
            }
        }
    }
    
    @objc func onStatusChat(notification: NSNotification) {
        DispatchQueue.main.async {
            let data:[AnyHashable : Any] = notification.userInfo!
            if let dataMessage = data["message"] as? TMessage {
                let idMe = User.getMyPin() as String?
                let chatData = dataMessage.mBodies
                if (chatData[CoreMessage_TMessageKey.F_PIN] == idMe || chatData[CoreMessage_TMessageKey.L_PIN] == self.dataGroup["group_id"] as? String || chatData[CoreMessage_TMessageKey.F_PIN] == self.dataGroup["group_id"] as? String) && chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID] == MessageScope.GROUP {
                    if (chatData.keys.contains(CoreMessage_TMessageKey.MESSAGE_ID) && !(chatData[CoreMessage_TMessageKey.MESSAGE_ID]!).contains("-2,")) {
                        var idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == chatData[CoreMessage_TMessageKey.MESSAGE_ID]! })
                        if let idxMessageIdParent = self.groupImages.firstIndex(where: { $0.value.contains(where: { $0.messageId == chatData[CoreMessage_TMessageKey.MESSAGE_ID]! }) }) {
                            if let idxInImages = self.groupImages[idxMessageIdParent].value.firstIndex(where: { $0.messageId == chatData[CoreMessage_TMessageKey.MESSAGE_ID]! }) {
                                self.groupImages[idxMessageIdParent].value[idxInImages].status = chatData[CoreMessage_TMessageKey.STATUS]!
                                self.groupImages[idxMessageIdParent].value[idxInImages].dataMessage["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
                            }
                            idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.groupImages[idxMessageIdParent].key })
                        }
                        if (idx != nil) {
                            if (chatData[CoreMessage_TMessageKey.DELETE_MESSAGE_FLAG] == "1") {
                                self.updateStatusDelete(idx: idx, chatData: chatData)
                            } else {
                                self.updateStatusMessage(idx: idx, chatData: chatData)
                            }
                        }
                    }
                    else if (chatData.keys.contains("message_id")) {
                        var idMessage = dataMessage.getBody(key: "message_id")
                        if idMessage.contains("'") {
                            idMessage = idMessage.replacingOccurrences(of: "'", with: "")
                        }
                        var idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == idMessage })
                        if let idxMessageIdParent = self.groupImages.firstIndex(where: { $0.value.contains(where: { $0.messageId == idMessage }) }) {
                            if let idxInImages = self.groupImages[idxMessageIdParent].value.firstIndex(where: { $0.messageId == idMessage }) {
                                self.groupImages[idxMessageIdParent].value[idxInImages].status = chatData[CoreMessage_TMessageKey.STATUS]!
                                self.groupImages[idxMessageIdParent].value[idxInImages].dataMessage["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
                            }
                            idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.groupImages[idxMessageIdParent].key })
                        }
                        if (idx != nil) {
                            if (chatData[CoreMessage_TMessageKey.DELETE_MESSAGE_FLAG] == "1") {
                                self.updateStatusDelete(idx: idx, chatData: chatData)
                            } else {
                                self.updateStatusMessage(idx: idx, chatData: chatData)
                            }
                        }
                    }
                    else {
                        let listMessageId = chatData[CoreMessage_TMessageKey.MESSAGE_ID]!.split(separator: ",")
                        for i in 1..<listMessageId.count {
                            var idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String ?? "" == listMessageId[i] })
                            if let idxMessageIdParent = self.groupImages.firstIndex(where: { $0.value.contains(where: { $0.messageId == listMessageId[i] }) }) {
                                if let idxInImages = self.groupImages[idxMessageIdParent].value.firstIndex(where: { $0.messageId == listMessageId[i] }) {
                                    self.groupImages[idxMessageIdParent].value[idxInImages].status = chatData[CoreMessage_TMessageKey.STATUS]!
                                    self.groupImages[idxMessageIdParent].value[idxInImages].dataMessage["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
                                }
                                idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.groupImages[idxMessageIdParent].key })
                            }
                            if (idx != nil) {
                                self.updateStatusMessage(idx: idx, chatData: chatData)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func onFailedSendMessage(notification: NSNotification) {
        DispatchQueue.main.async {
            let data:[AnyHashable : Any] = notification.userInfo!
            let messageId = data["message_id"]  as? String ?? ""
            let status = data["status"]  as? String ?? ""
            
            var idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String ?? "" == messageId })
            if let idxMessageIdParent = self.groupImages.firstIndex(where: { $0.value.contains(where: { $0.messageId == messageId }) }) {
                if let idxInImages = self.groupImages[idxMessageIdParent].value.firstIndex(where: { $0.messageId == messageId }) {
                    self.groupImages[idxMessageIdParent].value[idxInImages].status = status
                    self.groupImages[idxMessageIdParent].value[idxInImages].dataMessage["status"] = status
                }
                idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.groupImages[idxMessageIdParent].key })
            }
            
            if (idx != nil) {
                do {
                    self.dataMessages[idx!]["status"] = status
                    let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
                    let row = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataMessages[idx!]["chat_date"]  as? String ?? ""}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                    if row != nil && section != nil  {
                        self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                    }
                } catch {
                }
            }
        }
    }
    
    private func updateStatusDelete(idx: Int?, chatData: [String: String]) {
        do {
            if self.dataMessages[idx!]["lock"] != nil && self.dataMessages[idx!]["lock"]  as? String ?? "" == "1" {
                return
            }
            self.dataMessages[idx!]["lock"] = "1"
            self.dataMessages[idx!]["reff_id"] = ""
            let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
            let row = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataMessages[idx!]["chat_date"]  as? String ?? ""}).firstIndex(where: { $0["message_id"]  as? String ?? "" == self.dataMessages[idx!]["message_id"]  as? String ?? "" })
            if row != nil && section != nil  {
                self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
            }
            if self.listTimerCredential[self.dataMessages[idx!]["message_id"]  as? String ?? ""] != nil {
                self.listTimerCredential.removeValue(forKey: self.dataMessages[idx!]["message_id"]  as? String ?? "")
                self.timerCredential[self.dataMessages[idx!]["message_id"]  as? String ?? ""]?.invalidate()
                self.timerCredential.removeValue(forKey: self.dataMessages[idx!]["message_id"]  as? String ?? "")
                SecureUserDefaults.shared.removeValue(forKey: self.dataMessages[idx!]["message_id"]  as? String ?? "")
            }
            if self.reffId != nil && self.reffId == chatData["message_id"]! {
                self.deleteReplyView()
            }
        } catch {
        }
    }
    
    private func updateStatusMessage(idx: Int?, chatData: [String: String]) {
        do {
            if Int(self.dataMessages[idx!]["status"]  as? String ?? "")! > Int(chatData[CoreMessage_TMessageKey.STATUS]!)! {
                return
            }
            self.dataMessages[idx!]["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
            let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
            let row = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataMessages[idx!]["chat_date"]  as? String ?? ""}).firstIndex(where: { $0["message_id"]  as? String ?? "" == self.dataMessages[idx!]["message_id"]  as? String ?? "" })
            if row != nil && section != nil  {
                self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
            }
        } catch {
        }
    }
    
    @objc func onMemberTopic(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        DispatchQueue.main.async { [self] in
            if data["member"] == nil || data["code"]  as? String ?? "" == CoreMessage_TMessageCode.EXIT_GROUP && data["member"]  as? String ?? "" == User.getMyPin()! && data["groupId"]  as? String ?? "" == self.dataGroup["group_id"]  as? String ?? "" && !containerActionGroup.isDescendant(of: self.view) {
                dismissKeyboard()
                let labelKicked = UILabel()
                if data["member"] == nil && data["code"]  as? String ?? "" == CoreMessage_TMessageCode.DELETE_CHAT && data["topicId"]  as? String ?? "" == dataTopic["chat_id"]  as? String ?? "" {
                    labelKicked.text = "This topic has been deleted".localized()
                } else if data["member"] != nil && data["member"]  as? String ?? "" == data["f_pin"]  as? String ?? "" {
                    labelKicked.text = "You have left this group".localized()
                } else if data["member"] != nil {
                    labelKicked.text = "You have been removed from this group".localized()
                } else if data["code"]  as? String ?? "" == CoreMessage_TMessageCode.UPDATE_CHAT {
                    dataGroup.removeAll()
                    dataTopic.removeAll()
                    getDataGroup(unique_l_pin: unique_l_pin)
                    changeAppBar()
                    return
                } else {
                    return
                }
                removed = true
                cancelAction()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: { [self] in
                    navigationItem.rightBarButtonItem = nil
                    view.addSubview(containerActionGroup)
                    containerActionGroup.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        containerActionGroup.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                        containerActionGroup.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                        containerActionGroup.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                        containerActionGroup.heightAnchor.constraint(equalToConstant: 120)
                    ])
                    containerActionGroup.backgroundColor = .secondaryColor.withAlphaComponent(0.8)
                    containerActionGroup.addSubview(labelKicked)
                    labelKicked.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        labelKicked.centerYAnchor.constraint(equalTo: containerActionGroup.centerYAnchor),
                        labelKicked.centerXAnchor.constraint(equalTo: containerActionGroup.centerXAnchor),
                    ])
                    labelKicked.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
                    labelKicked.font = UIFont.systemFont(ofSize: 12 + offset()).bold
                    if contactChatNav.viewIfLoaded?.window != nil {
                        contactChatNav.dismiss(animated: true)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                        if self.fromNotification {
                            self.didTapExit()
                        } else {
                            self.navigationController?.popViewController(animated: true)
                        }
                    })
                })
            }
        }
    }
    
    @objc func onGroup(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        if data["code"]  as? String ?? "" == "A010" && data["groupId"]  as? String ?? "" == self.dataGroup["group_id"]  as? String ?? "" {
            DispatchQueue.main.async {
                Database.shared.database?.inTransaction({ fmdb, rollback in
                    if let c = Database().getRecords(fmdb: fmdb, query: "select f_name, image_id from GROUPZ where group_id = '\(self.dataGroup["group_id"]!!)'"), c.next() {
                        self.dataGroup["f_name"] = c.string(forColumnIndex: 0)!.trimmingCharacters(in: .whitespacesAndNewlines)
                        self.dataGroup["image_id"] = c.string(forColumnIndex: 1)!
                        c.close()
                    }
                })
                self.changeAppBar()
            }
        }
    }
    
    @IBAction func voiceTapped(_ sender: UIButton) {
        if (self.constraintBottomAttachment.constant != 0.0) {
            constraintBottomAttachment.constant = 0.0
            self.viewSticker.removeConstraints(self.viewSticker.constraints)
            self.viewSticker.removeFromSuperview()
        }
    }
    
    @IBAction func imageTapped(_ sender: UIButton) {
        if (self.constraintBottomAttachment.constant != 0.0) {
            constraintBottomAttachment.constant = 0.0
            self.viewSticker.removeConstraints(self.viewSticker.constraints)
            self.viewSticker.removeFromSuperview()
        }
        let alertController = LibAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if let action = self.actionImageVideo(for: "image", title: "Choose Photo".localized()) {
            alertController.addAction(action)
        }
        if let action = self.actionImageVideo(for: "video", title: "Choose Video".localized()) {
            alertController.addAction(action)
        }
        alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        self.present(alertController, animated: true)
    }
    
    private func actionImageVideo(for type: String, title: String) -> UIAlertAction? {
        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            switch type {
            case "image":
                var config = PHPickerConfiguration()
                config.filter = .images
                config.preferredAssetRepresentationMode = .automatic
                let picker = PHPickerViewController(configuration: config)
                picker.delegate = self
                if UIBarButtonItem.appearance().titleTextAttributes(for: .normal) != nil {
                    isBlackCancelButton = UIBarButtonItem.appearance().titleTextAttributes(for: .normal)?.values.first as! NSObject == UIColor.black
                }
                if !isBlackCancelButton {
                    let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
                    UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes , for: .normal)
                }
                present(picker, animated: true, completion: nil)
            case "video":
                var config = PHPickerConfiguration()
                config.filter = .videos
                config.preferredAssetRepresentationMode = .automatic
                let picker = PHPickerViewController(configuration: config)
                picker.delegate = self
                if UIBarButtonItem.appearance().titleTextAttributes(for: .normal) != nil {
                    isBlackCancelButton = UIBarButtonItem.appearance().titleTextAttributes(for: .normal)?.values.first as! NSObject == UIColor.black
                }
                if !isBlackCancelButton {
                    let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
                    UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes , for: .normal)
                }
                present(picker, animated: true, completion: nil)
            case "imageCamera":
                imageVideoPicker.present(source: .imageCamera)
            case "videoCamera":
                imageVideoPicker.present(source: .videoCamera)
            default:
                imageVideoPicker.present(source: .imageAlbum)
            }
        }
    }
    
    @IBAction func photoTapped(_ sender: UIButton) {
        if (self.constraintBottomAttachment.constant != 0.0) {
            constraintBottomAttachment.constant = 0.0
            self.viewSticker.removeConstraints(self.viewSticker.constraints)
            self.viewSticker.removeFromSuperview()
        }
        let alertController = LibAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if let action = self.actionImageVideo(for: "imageCamera", title: "Take Photo".localized()) {
            alertController.addAction(action)
        }
        if let action = self.actionImageVideo(for: "videoCamera", title: "Take Video".localized()) {
            alertController.addAction(action)
        }
        alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        self.present(alertController, animated: true)
    }
    
    @IBAction func stickerTapped(_ sender: UIButton) {
        if textFieldSend.isFirstResponder {
            dismissKeyboard()
        }
        DispatchQueue.main.async {
            if !self.viewSticker.isDescendant(of: self.view) {
                self.constraintBottomAttachment.constant = 200.0
                self.view.addSubview(self.viewSticker)
                self.viewSticker.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    self.viewSticker.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                    self.viewSticker.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    self.viewSticker.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                    self.viewSticker.heightAnchor.constraint(equalToConstant: 200)
                ])
                
                let layout = UICollectionViewFlowLayout()
                layout.scrollDirection = .vertical
                let collectionSticker = UICollectionView(frame: .zero, collectionViewLayout: layout)
                collectionSticker.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cellSticker")
                collectionSticker.delegate = self
                collectionSticker.dataSource = self
                collectionSticker.backgroundColor = .clear
                self.viewSticker.addSubview(collectionSticker)
                collectionSticker.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    collectionSticker.topAnchor.constraint(equalTo: self.viewSticker.topAnchor, constant: 20),
                    collectionSticker.bottomAnchor.constraint(equalTo: self.viewSticker.bottomAnchor, constant: -20),
                    collectionSticker.leadingAnchor.constraint(equalTo: self.viewSticker.leadingAnchor, constant: 20),
                    collectionSticker.trailingAnchor.constraint(equalTo: self.viewSticker.trailingAnchor, constant: -20)
                ])
                if (self.currentIndexpath != nil) {
                    DispatchQueue.main.async {
                        self.tableChatView.scrollToRow(at: IndexPath(row: self.currentIndexpath!.row, section: self.currentIndexpath!.section), at: .none, animated: false)
                    }
                } else {
                    self.tableChatView.scrollToBottom()
                }
            } else {
                self.constraintBottomAttachment.constant = 0.0
                self.viewSticker.removeConstraints(self.viewSticker.constraints)
                self.viewSticker.removeFromSuperview()
            }
        }
    }
    
    @IBAction func fileTapped(_ sender: UIButton) {
        if (self.constraintBottomAttachment.constant != 0.0) {
            constraintBottomAttachment.constant = 0.0
            self.viewSticker.removeConstraints(self.viewSticker.constraints)
            self.viewSticker.removeFromSuperview()
        }
        documentPicker.present()
    }
    
    @objc func didTapExit() {
        self.dismiss(animated: true, completion: {
            self.removeAllObjectBeforeDismissVC()
        })
    }
    
    @objc func profilePersonTapped(_ sender: ObjectGesture) {
        if isHistoryCC {
            return
        }
        let idMe = User.getMyPin() as String?
        if sender.message_id == idMe {
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
            controller.data = sender.message_id
            controller.flag = .me
            navigationController?.show(controller, sender: nil)
        } else if sender.message_id != "-999" && sender.message_id != "-997"  {
            let data = User.getDataCanNil(pin: sender.message_id)
            if data != nil {
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
                controller.flag = .friend
                controller.user = data
                controller.name = data!.fullName
                controller.data = sender.message_id
                controller.picture = data!.thumb
                self.navigationController?.show(controller, sender: nil)
            } else {
                let dataUser = getDataProfile(f_pin: sender.message_id, message_id: "")
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
                controller.flag = .invite
                controller.user = nil
                controller.name = dataUser["name"]!
                controller.data = sender.message_id
                controller.picture = dataUser["image_id"]!
                self.navigationController?.show(controller, sender: nil)
            }
        }
    }
    
    @objc func seeProfileTapped() {
        if isHistoryCC || removed || copySession || forwardSession || deleteSession || (dataGroup["official"] as? String == "1" && (dataGroup["parent"] as? String)!.isEmpty) {
            return
        }
        dismissKeyboard()
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "groupDetailView") as! GroupDetailViewController
        controller.data = dataGroup["group_id"]  as? String ?? ""
        controller.checkReadMessage = {
            if self.currentIndexpath == nil {
                var listData = self.dataMessages
                listData = listData.filter({$0["status"]  as? String ?? "" != "4" && $0["status"]  as? String ?? "" != "8"})
                if listData.count != 0 {
                    let idMe = User.getMyPin() as String?
                    for i in 0...listData.count - 1 {
                        if listData[i]["f_pin"] as? String != idMe {
                            self.sendReadMessageStatus(chat_id: self.dataTopic["chat_id"]  as? String ?? "", f_pin: listData[i]["f_pin"]  as? String ?? "", message_scope_id: MessageScope.GROUP, message_id: listData[i]["message_id"]  as? String ?? "")
                        }
                    }
                }
            } else {
                let dataMessages = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataDates[self.currentIndexpath!.section] })
                var listData = dataMessages
                listData = listData.filter({$0["status"]  as? String ?? "" != "4" && $0["status"]  as? String ?? "" != "8"})
                if listData.count != 0 {
                    let idMe = User.getMyPin() as String?
                    for i in 0...listData.count - 1 {
                        if listData[i]["f_pin"] as? String != idMe {
                            self.sendReadMessageStatus(chat_id: self.dataTopic["chat_id"]  as? String ?? "", f_pin: listData[i]["f_pin"]  as? String ?? "", message_scope_id: MessageScope.GROUP, message_id: listData[i]["message_id"]  as? String ?? "")
                        }
                    }
                }
            }
        }
        navigationController?.show(controller, sender: nil)
    }
    
    @objc func dismissKeyboard() {
        if isSearching {
            searchBar.resignFirstResponder()
        } else {
            textFieldSend.resignFirstResponder() // dismiss keyoard
            if (self.constraintBottomAttachment.constant != 0.0) {
                constraintBottomAttachment.constant = 0.0
                self.viewSticker.removeConstraints(self.viewSticker.constraints)
                self.viewSticker.removeFromSuperview()
            }
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if self.viewIfLoaded?.window != nil && !isEditingMessage {
            if (self.constraintBottomAttachment.constant != 0.0) {
                self.constraintBottomAttachment.constant = 0.0
                self.viewSticker.removeConstraints(self.viewSticker.constraints)
                self.viewSticker.removeFromSuperview()
            }
            let info:NSDictionary = notification.userInfo! as NSDictionary
            let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            
            let keyboardHeight: CGFloat = keyboardSize.height
            
            let duration: CGFloat = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber as! CGFloat
            
            if self.constraintBottomAttachment.constant != keyboardHeight || self.constraintViewTextField.constant != keyboardHeight - 60 {
//                self.constraintViewTextField.constant = keyboardHeight - 60
                self.constraintBottomAttachment.constant = keyboardHeight
                if self.contraintBottomMention.constant > 0 {
                    self.contraintBottomMention.constant = 25 + constraintBottomAttachment.constant + self.heightTextFieldSend.constant + self.viewTextfield.bounds.height
                }
                self.keyboardHeightForMention = keyboardHeight
                if isSearching {
                    self.constraintBottomContainerMultpileSelectSession.constant = -keyboardHeight
                }
                UIView.animate(withDuration: TimeInterval(duration), animations: {
                    self.view.layoutIfNeeded()
                })
                if (self.currentIndexpath != nil) {
                    self.tableChatView.scrollToRow(at: IndexPath(row: self.currentIndexpath!.row, section: self.currentIndexpath!.section), at: .none, animated: false)
                } else {
                    self.tableChatView.scrollToBottom()
                }
            }
        }  else if isEditingMessage {
            let info:NSDictionary = notification.userInfo! as NSDictionary
            let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            
            let keyboardHeight: CGFloat = keyboardSize.height
            
            let duration: CGFloat = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber as! CGFloat
            let constant: CGFloat = 0 - keyboardHeight - 15
            constraintBottomeditTextView.constant = constant
            constraintBottomSendEditTV.constant = constant
            UIView.animate(withDuration: TimeInterval(duration), animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.viewIfLoaded?.window != nil && !isEditingMessage {
            let info:NSDictionary = notification.userInfo! as NSDictionary
            let duration: CGFloat = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber as! CGFloat
            
            self.constraintViewTextField.constant = 0
            self.constraintBottomAttachment.constant = 0
            self.constraintBottomContainerMultpileSelectSession.constant = 0
            if self.contraintBottomMention.constant > 0 {
                self.contraintBottomMention.constant = 25 + constraintBottomAttachment.constant + self.heightTextFieldSend.constant + self.viewTextfield.bounds.height
            }
            keyboardHeightForMention = nil
            UIView.animate(withDuration: TimeInterval(duration), animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func showChooserACKConfidential() {
//        dismissKeyboard()
        let alertController = LibAlertController(title: "Message Mode".localized(), message: "Select".localized() + " " + "Message Mode".localized(), preferredStyle: .actionSheet)
        let imageConfidential = resizeImage(image: UIImage(named: "pb_icon_conf_msg_on", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
        let imageAck = resizeImage(image: UIImage(named: "pb_icon_ack_msg_on", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
        let imageSticker = resizeImage(image: UIImage(named: "Sticker---Emoji", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
        let confidentialAction = UIAlertAction(title: "Confidential Message".localized(), style: .default, handler: { (UIAlertAction) in
            self.isConfidential = !self.isConfidential
            if self.isConfidential {
                self.buttonAckConfidential.setImage(imageConfidential, for: .normal)
            } else {
                self.buttonAckConfidential.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.white).withRenderingMode(.alwaysTemplate), for: .normal)
            }
            if self.isAck {
                self.isAck = false
            }
        })
        let ackAction = UIAlertAction(title: "Confirmation Message".localized(), style: .default, handler: { (UIAlertAction) in
            self.isAck = !self.isAck
            if self.isAck {
                self.buttonAckConfidential.setImage(imageAck, for: .normal)
            } else {
                self.buttonAckConfidential.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.white).withRenderingMode(.alwaysTemplate), for: .normal)
            }
            if self.isConfidential {
                self.isConfidential = false
            }
        })
        let stickerAction = UIAlertAction(title: "Open Sticker".localized(), style: .default, handler: { (UIAlertAction) in
            self.stickerTapped(UIButton())
        })
        confidentialAction.setValue(imageConfidential, forKey: "image")
        ackAction.setValue(imageAck, forKey: "image")
        stickerAction.setValue(imageSticker, forKey: "image")
        alertController.addAction(confidentialAction)
        alertController.addAction(ackAction)
//        alertController.addAction(stickerAction)
        alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (UIAlertAction) in
            self.isConfidential = false
            self.isAck = false
            self.buttonAckConfidential.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.white).withRenderingMode(.alwaysTemplate), for: .normal)
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    public func setAckConfidential(isAck: Bool, isConfidential: Bool) {
        self.isConfidential = isConfidential
        self.isAck = isAck
        let imageConfidential = resizeImage(image: UIImage(named: "confidential_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
        let imageAck = resizeImage(image: UIImage(named: "ack_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
        if isAck {
            buttonAckConfidential.setImage(imageAck, for: .normal)
        } else if isConfidential {
            buttonAckConfidential.setImage(imageConfidential, for: .normal)
        } else {
            self.buttonAckConfidential.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.white).withRenderingMode(.alwaysTemplate), for: .normal)
        }
    }
    
    @objc func sendTapped() {
        sendChat(message_text: textFieldSend.text!, viewController: self)
    }
    
    private func sendChat(message_scope_id:String =  MessageScope.GROUP, status:String =  "1", message_text:String =  "", credential:String = "0", attachment_flag: String = "0", ex_blog_id: String = "", message_large_text: String = "", ex_format: String = "", image_id: String = "", audio_id: String = "", video_id: String = "", file_id: String = "", thumb_id: String = "", reff_id: String = "", read_receipts: String = "", is_call_center: String = "0", call_center_id: String = "", viewController: UIViewController, gif_id: String = "", is_forwarded: Int = 0) {
        if viewController is EditorGroup && file_id == "" && dataMessageForward == nil {
            if ((textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) == "Send message".localized() && textFieldSend.textColor == UIColor.lightGray && attachment_flag != "11") || textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ) {
                dismissKeyboard()
                viewController.view.makeToast("Write Messages".localized(), duration: 3)
                if (textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "Send message".localized()) {
                    textFieldSend.text = ""
                }
                if (self.heightTextFieldSend.constant != 40) {
                    self.heightTextFieldSend.constant = 40
                }
                return
            }
        }
        var reff_id = reff_id
        if (reffId != nil) {
            reff_id = reffId!
        }
        var message_text = message_text
        message_text = message_text.replacingOccurrences(of: "\n  •", with: "\n•")
        if message_text.hasPrefix("  •") {
            message_text = message_text.replacingOccurrences(of: "  •", with: "•")
        }
        let regex = try! NSRegularExpression(pattern: #"(?m)^\s{2}([0-9]+\.)"#)
        message_text = regex.stringByReplacingMatches(in: message_text,
                                                     options: [],
                                                     range: NSRange(location: 0, length: message_text.utf16.count),
                                                     withTemplate: "$1")
        

        // Check if text contains bullet points or numbered list using regex
        if !message_text.isEmpty {
            message_text = message_text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let idMe = User.getMyPin() as String?
        var opposite_pin = self.dataGroup["group_id"]  as? String ?? ""
        if (self.dataTopic["chat_id"]  as? String ?? "" != "") {
            opposite_pin = self.dataTopic["chat_id"]  as? String ?? ""
        }
        var credential = credential
        if isConfidential {
            credential = "1"
        }
        var read_receipts = read_receipts
        if isAck {
            read_receipts = "8"
        }
        if message_text.contains("@") && listMentionInTextField.count > 0 {
            var diff: Int = 0
            for i in 0..<listMentionInTextField.count {
                let mention = listMentionInTextField[i]
                guard let exBlockStr = mention.ex_block, let exBlock = Int(exBlockStr) else {
                    continue // skip if ex_block is nil or not an integer
                }
                let nameWithMention = ("@" + mention.fullName).trimmingCharacters(in: .whitespaces)
                let pinString = "@\(mention.pin)"
                let upperBound = exBlock + diff
                let lowerBound = upperBound - nameWithMention.count + 1
                guard lowerBound >= 0, upperBound < message_text.count else {
                    continue // prevent index out-of-range
                }
                var afterMention = ""
                let nextCharIndex = message_text.index(message_text.startIndex, offsetBy: upperBound + 1, limitedBy: message_text.endIndex)
                if let index = nextCharIndex, index < message_text.endIndex {
                    let nextChar = message_text[index]
                    if nextChar != "\n" && nextChar != " " {
                        afterMention = " "
                    }
                }
                let startIndex = message_text.index(message_text.startIndex, offsetBy: lowerBound)
                let endIndex = message_text.index(message_text.startIndex, offsetBy: upperBound + 1)
                let range = startIndex..<endIndex
                if message_text[range] == nameWithMention {
                    message_text.replaceSubrange(range, with: pinString + afterMention)
                    diff += (pinString + afterMention).count - nameWithMention.count
                }
            }
        }
        if Nexilis.checkingAccess(key: "message_guard") {
            let guardLite = MessageGuardLite(limits: .defaults())
            var isSanitizedText = false
            var isSanitizedHtml = false
            let res = guardLite.sanitizeText(message_text.data(using: .utf8)!)
            if res.verdict == .sanitized {
                isSanitizedText = true
            }
            if let clean = res.data, let str = String(data: clean, encoding: .utf8) {
                if MessageGuardLite.containsHtmlTags(str) {
                    let res2 = guardLite.sanitizeHtml(res.data ?? Data())
                    if res2.verdict == .sanitized {
                        isSanitizedHtml = true
                    }
                    if let str2 = String(data: clean, encoding: .utf8), isSanitizedHtml {
                        message_text = str2
                    }
                } else if isSanitizedText {
                    message_text = str
                }
            }
            var protectionType = ""
            if isSanitizedText && isSanitizedHtml {
                protectionType = "text & html"
            } else if isSanitizedText {
                protectionType = "text"
            } else if isSanitizedHtml {
                protectionType = "html"
            }
            
            if !protectionType.isEmpty {
                DispatchQueue.main.async {
                    self.view.makeToast("Your message is protected with sanitized \(protectionType) (Message Guard)".localized(), duration: 3, position: .center)
                }
            }
        }
        let message = CoreMessage_TMessageBank.sendMessage(l_pin: dataGroup["group_id"]  as? String ?? "", message_scope_id: message_scope_id, status: status, message_text: message_text, credential: credential, attachment_flag: attachment_flag, ex_blog_id: ex_blog_id, message_large_text: message_large_text, ex_format: ex_format, image_id: image_id, audio_id: audio_id, video_id: video_id, file_id: file_id, thumb_id: thumb_id, reff_id: reff_id, read_receipts: read_receipts, chat_id: dataTopic["chat_id"]  as? String ?? "", is_call_center: is_call_center, call_center_id: call_center_id, opposite_pin: opposite_pin, gif_id: gif_id, isForwarded: "\(is_forwarded)", specFile: specFileString)
        Nexilis.addQueueMessage(message: message)
        let messageId = String(message.mBodies[CoreMessage_TMessageKey.MESSAGE_ID]!)
        if credential == "1" {
            self.listTimerCredential[messageId] = 60
        }
        var row: [String: Any?] = [:]
        row["message_id"] = messageId
        row["f_pin"] = idMe
        row["l_pin"] = dataGroup["group_id"]!!
        row["message_scope_id"] = message_scope_id
        row["server_date"] = "\(Date().currentTimeMillis())"
        row["status"] = status
        row["message_text"] = message_text
        row["audio_id"] = audio_id
        row["video_id"] = video_id
        row["image_id"] = image_id
        row["thumb_id"] = thumb_id
        row["credential"] = credential
        row["read_receipts"] = read_receipts
        row["chat_id"] = dataTopic["chat_id"]!!
        row["file_id"] = file_id
        row["attachment_flag"] = attachment_flag
        row["reff_id"] = reff_id
        row["progress"] = 0.0
        row["lock"] = "0"
        row["is_stared"] = "0"
        row["isSelected"] = false
        row["gif_id"] = gif_id
        row[TypeDataMessage.is_forwarded] = is_forwarded
        row[TypeDataMessage.is_call_center] = is_call_center
        row[TypeDataMessage.call_center_id] = call_center_id
        row[TypeDataMessage.opposite_pin] = opposite_pin
        row[TypeDataMessage.spec_file] = specFileString
        specFileString = ""
        lastTextLength = 0
        if !dataDates.contains("Today".localized()){
            dataDates.append("Today".localized())
            tableChatView.insertSections(IndexSet(integer: dataDates.count - 1), with: .fade)
        }
        row["chat_date"] = "Today".localized()
        self.tableChatView.beginUpdates()
        dataMessages.append(row)
        tableChatView.insertRows(at: [IndexPath(row: dataMessages.filter({ $0["chat_date"]  as? String ?? "" == dataDates[dataDates.count - 1]}).count - 1, section: dataDates.count - 1)], with: .fade)
        self.tableChatView.endUpdates()
        if credential == "1" {
            var timer = Timer()
            var minute = 60
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {_ in
                minute -= 1
                self.listTimerCredential[messageId] = minute
                if minute == 0 {
                    timer.invalidate()
                    self.listTimerCredential.removeValue(forKey: messageId)
                    self.timerCredential.removeValue(forKey: messageId)
                    let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == messageId})
                    if idx != nil {
                        self.dataMessages[idx!]["lock"] = "2"
                        self.dataMessages[idx!]["reff_id"] = ""
                    }
                    DispatchQueue.global().async {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                    "lock" : "2"
                                ], _where: "message_id = '\(messageId)'")
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                    }
                }
                let section = self.dataDates.firstIndex(of: self.dataDates[self.dataDates.count - 1])
                let row = self.dataMessages.filter({$0["chat_date"]  as? String ?? "" == self.dataDates[self.dataDates.count - 1]}).firstIndex(where: { $0["message_id"] as? String == messageId})
                if row != nil && section != nil{
                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                }
            })
            self.timerCredential[messageId] = timer
        }
        if textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "Send message".localized() && textFieldSend.textColor != UIColor.lightGray && constraintBottomAttachment.constant == 0 {
            textFieldSend.text = "Send message".localized()
            textFieldSend.textColor = UIColor.lightGray
        } else if constraintBottomAttachment.constant != 0 {
            textFieldSend.text = ""
            heightTextFieldSend.constant = 40
        }
        deleteReplyView()
        deleteLinkPreview()
        listMentionInTextField.removeAll()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
        self.tableChatView.scrollToBottom()
        if self.markerCounter != nil {
            let lastMarkerCounter = self.markerCounter
            self.markerCounter = nil
            let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == lastMarkerCounter })
            if indexMessage != nil {
                let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"]  as? String ?? "")
                let row = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataMessages[indexMessage!]["chat_date"]  as? String ?? ""}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                if row != nil && section != nil  {
                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                }
            }
        }
    }
    
    private func getCounter() {
        Database.shared.database?.inTransaction({ fmdb, rollback in
            var l_pin = self.dataGroup["group_id"] as? String ?? ""
            if (self.dataTopic["chat_id"]  as? String ?? "" != "") {
                l_pin = self.dataTopic["chat_id"]  as? String ?? ""
            }
            
            if let c = Database().getRecords(fmdb: fmdb, query: "SELECT counter FROM MESSAGE_SUMMARY where l_pin='\(l_pin)'"), c.next() {
                counter = Int(c.int(forColumnIndex: 0))
                c.close()
            }
        })
    }
    
    private func updateCounter(counter: Int) {
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    var l_pin = self.dataGroup["group_id"]!!
                    if (self.dataTopic["chat_id"]  as? String ?? "" != "") {
                        l_pin = self.dataTopic["chat_id"]  as? String ?? ""
                    }
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                        "counter" : "\(counter)"
                    ], _where: "l_pin = '\(l_pin)'")
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
        }
        
    }
    
    private func disableEditor() {
        view.addSubview(containerAction)
        containerAction.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerAction.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            containerAction.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            containerAction.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            containerAction.heightAnchor.constraint(equalToConstant: 120)
        ])
        containerAction.backgroundColor = .secondaryColor.withAlphaComponent(0.8)
        let labelDisable = UILabel()
        containerAction.addSubview(labelDisable)
        labelDisable.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelDisable.centerYAnchor.constraint(equalTo: containerAction.centerYAnchor),
            labelDisable.centerXAnchor.constraint(equalTo: containerAction.centerXAnchor),
        ])
        labelDisable.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        labelDisable.font = UIFont.systemFont(ofSize: 12 + offset()).bold
        labelDisable.text = "Call Center Session has ended".localized()
    }
    
    private func addButtonScrollToBottom() {
        if tableChatView.alpha != 1 || isSearching {
            return
        }
        self.view.addSubview(buttonScrollToBottom)
        buttonScrollToBottom.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonScrollToBottom.bottomAnchor.constraint(equalTo: buttonSendChat.topAnchor, constant: -50),
            buttonScrollToBottom.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            buttonScrollToBottom.widthAnchor.constraint(equalToConstant: 60),
            buttonScrollToBottom.heightAnchor.constraint(equalToConstant: 30.0)
        ])
        buttonScrollToBottom.backgroundColor = .greenColor
        buttonScrollToBottom.setImage(UIImage(systemName: "chevron.down.circle"), for: .normal)
        buttonScrollToBottom.imageView?.contentMode = .scaleAspectFit
        buttonScrollToBottom.imageView?.tintColor = .white
        buttonScrollToBottom.contentVerticalAlignment = .fill
        buttonScrollToBottom.contentHorizontalAlignment = .fill
        buttonScrollToBottom.imageEdgeInsets.top = 2.0
        buttonScrollToBottom.imageEdgeInsets.bottom = 2.0
        buttonScrollToBottom.layer.cornerRadius = 10.0
        buttonScrollToBottom.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        buttonScrollToBottom.clipsToBounds = true
        buttonScrollToBottom.addTarget(self, action: #selector(scrollTobottomAction), for: .touchUpInside)
    }
    
    private func addCounterAtButttonScrollToBottom() {
        if tableChatView.alpha != 1 || isSearching {
            return
        }
        self.view.addSubview(indicatorCounterBSTB)
        indicatorCounterBSTB.translatesAutoresizingMaskIntoConstraints = false
        indicatorCounterBSTB.backgroundColor = .systemRed
        indicatorCounterBSTB.layer.cornerRadius = 7.5
        indicatorCounterBSTB.clipsToBounds = true
        indicatorCounterBSTB.layer.borderWidth = 0.5
        indicatorCounterBSTB.layer.borderColor = UIColor.secondaryColor.cgColor
        NSLayoutConstraint.activate([
            indicatorCounterBSTB.bottomAnchor.constraint(equalTo: buttonScrollToBottom.topAnchor, constant: 5),
            indicatorCounterBSTB.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -50),
            indicatorCounterBSTB.widthAnchor.constraint(greaterThanOrEqualToConstant: 15),
            indicatorCounterBSTB.heightAnchor.constraint(equalToConstant: 15)
        ])
        
        indicatorCounterBSTB.addSubview(labelCounter)
        labelCounter.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelCounter.leadingAnchor.constraint(equalTo: indicatorCounterBSTB.leadingAnchor, constant: 2),
            labelCounter.trailingAnchor.constraint(equalTo: indicatorCounterBSTB.trailingAnchor, constant: -2),
            labelCounter.centerXAnchor.constraint(equalTo: indicatorCounterBSTB.centerXAnchor),
        ])
        labelCounter.font = UIFont.systemFont(ofSize: 11 + offset())
        labelCounter.text = "\(counter)"
        labelCounter.textColor = .secondaryColor
        labelCounter.textAlignment = .center
    }
    
    @objc func scrollTobottomAction() {
        tableChatView.scrollToBottom()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [self] in
            if buttonScrollToBottom.isDescendant(of: self.view) {
                buttonScrollToBottom.removeConstraints(buttonScrollToBottom.constraints)
                buttonScrollToBottom.removeFromSuperview()
                if indicatorCounterBSTB.isDescendant(of: self.view) {
                    indicatorCounterBSTB.removeConstraints(indicatorCounterBSTB.constraints)
                    indicatorCounterBSTB.removeFromSuperview()
                }
            }
        }
    }
    
    private func sendReadMessageStatus(chat_id: String, f_pin: String, message_scope_id: String, message_id: String) {
        let message = CoreMessage_TMessageBank.getUpdateRead(p_chat_id: chat_id, p_f_pin: f_pin, p_scope_id: message_scope_id, qty: 1)
        let fPin = message.getBody(key: CoreMessage_TMessageKey.F_PIN)
        let scope = message.getBody(key: CoreMessage_TMessageKey.SCOPE_ID)
        message.mBodies[CoreMessage_TMessageKey.SERVER_DATE] = String(Date().currentTimeMillis())
        if let listGroupImages = self.groupImages.first(where: { $0.key == message_id }) {
            let valueListGroupImages = listGroupImages.value
            message.mStatus = CoreMessage_TMessageUtil.getTID()
            message.mBodies[CoreMessage_TMessageKey.L_PIN] = f_pin
            var mId = ""
            for i in 0..<valueListGroupImages.count {
                if mId.isEmpty {
                    mId = "-2,\(valueListGroupImages[i].messageId)"
                } else {
                    mId = mId + "," + valueListGroupImages[i].messageId
                }
            }
            message.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = mId
        } else {
            message.mStatus = CoreMessage_TMessageUtil.getTID()
            message.mBodies[CoreMessage_TMessageKey.L_PIN] = f_pin
            message.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = "-2,\(message_id)"
        }
        if (fPin.elementsEqual("-999") || scope.elementsEqual("16") || scope.elementsEqual("15")){
            return
        }
        DispatchQueue.global().async {
            var isBackground = true
            while isBackground {
                DispatchQueue.main.sync {
                    isBackground = API.nGetCLXConnState() == 0 || !API.bInetConnAvailable() || APIS.checkAppStateisBackground()
                }
                if isBackground {
                    Thread.sleep(forTimeInterval: 1.0)
                } else {
                    if let resp = Nexilis.writeAndWait(message: message) {
                        if resp.isOk() {
                            if let listGroupImages = self.groupImages.first(where: { $0.key == message_id }) {
                                let valueListGroupImages = listGroupImages.value
                                for i in 0..<valueListGroupImages.count {
                                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                        do {
                                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                                "status" : "4"
                                            ], _where: "message_id = '\(valueListGroupImages[i].messageId)'")
                                        } catch {
                                            rollback.pointee = true
                                            print("Access database error: \(error.localizedDescription)")
                                        }
                                    })
                                }
                            } else {
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                            "status" : "4"
                                        ], _where: "message_id = '\(message_id)'")
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                            }
                        } else {
                            DispatchQueue.main.sync {
                                self.sendReadMessageStatus(chat_id: chat_id, f_pin: fPin, message_scope_id: message_scope_id, message_id: message_id)
                            }
                        }
                    } else {
                        DispatchQueue.main.sync {
                            self.sendReadMessageStatus(chat_id: chat_id, f_pin: fPin, message_scope_id: message_scope_id, message_id: message_id)
                        }
                    }
                }
            }
        }
        if let index = dataMessages.firstIndex(where: {$0["message_id"] as? String == message_id}) {
            dataMessages[index]["status"] = "4"
            let auto: Bool = SecureUserDefaults.shared.value(forKey: "autoDownload") ?? false
            if auto {
                if dataMessages[index]["image_id"] as? String != nil && !((dataMessages[index]["image_id"] as? String)!.isEmpty) {
                    Download().startHTTP(forKey:dataMessages[index]["image_id"]  as? String ?? "") { (name, progress) in
                        guard progress == 100 else {
                            return
                        }
                        do {
                            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                            if let dirPath = paths.first {
                                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(self.dataMessages[index]["image_id"]  as? String ?? "")
                                if FileManager.default.fileExists(atPath: imageURL.path) {
                                    let image    = UIImage(contentsOfFile: imageURL.path)
                                    let save: Bool = SecureUserDefaults.shared.value(forKey: "saveToGallery") ?? false
                                    if save {
                                        UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
                                    }
                                }
                                else if FileEncryption.shared.isSecureExists(filename: self.dataMessages[index]["image_id"]  as? String ?? "") {
                                    if var secureData = try FileEncryption.shared.readSecure(filename: self.dataMessages[index]["image_id"]  as? String ?? "") {
                                        let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: secureData)
                                        if dataDecrypt != nil {
                                            secureData = dataDecrypt!
                                        }
                                        let image = UIImage(data: secureData)
                                        let save: Bool = SecureUserDefaults.shared.value(forKey: "saveToGallery") ?? false
                                        if save {
                                            UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
                                        }
                                    }
                                }
                            }
                        } catch {
                            
                        }
                        DispatchQueue.main.async { [self] in
                            let section = dataDates.firstIndex(of: dataMessages[index]["chat_date"]  as? String ?? "")
                            let row = dataMessages.filter({$0["chat_date"]  as? String ?? "" == dataMessages[index]["chat_date"]  as? String ?? ""}).firstIndex(where: { $0["message_id"] as? String == message_id})
                            if row != nil && section != nil{
                                tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .automatic)
                            }
                        }
                    }
                } else if dataMessages[index]["video_id"] as? String != nil && !((dataMessages[index]["video_id"] as? String)!.isEmpty){
                    Download().startHTTP(forKey: dataMessages[index]["video_id"]  as? String ?? "") { (name, progress) in
                        guard progress == 100 else {
                            return
                        }
                        do {
                            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                            if let dirPath = paths.first {
                                let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(self.dataMessages[index]["video_id"]  as? String ?? "")
                                if FileManager.default.fileExists(atPath: videoURL.path) {
                                    let save: Bool = SecureUserDefaults.shared.value(forKey: "saveToGallery") ?? false
                                    if save {
                                        PHPhotoLibrary.shared().performChanges({
                                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                                        }) { saved, error in
                                            
                                        }
                                    }
                                }
                                else if FileEncryption.shared.isSecureExists(filename: self.dataMessages[index]["video_id"]  as? String ?? "") {
                                    if var secureData = try FileEncryption.shared.readSecure(filename: self.dataMessages[index]["video_id"]  as? String ?? "") {
                                        let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: secureData)
                                        if dataDecrypt != nil {
                                            secureData = dataDecrypt!
                                        }
                                        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                                        let tempPath = cachesDirectory.appendingPathComponent(name)
                                        try secureData.write(to: tempPath)
                                        let save: Bool = SecureUserDefaults.shared.value(forKey: "saveToGallery") ?? false
                                        if save {
                                            PHPhotoLibrary.shared().performChanges({
                                                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempPath)
                                            }) { saved, error in
                                                
                                            }
                                        }
                                    }
                                }
                            }
                            DispatchQueue.main.async { [self] in
                                let section = dataDates.firstIndex(of: dataMessages[index]["chat_date"]  as? String ?? "")
                                let row = dataMessages.filter({$0["chat_date"]  as? String ?? "" == dataMessages[index]["chat_date"]  as? String ?? ""}).firstIndex(where: { $0["message_id"] as? String == message_id})
                                if row != nil && section != nil{
                                    tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .automatic)
                                }
                            }
                        }
                        catch {
                            
                        }
                    }
                }
                else if dataMessages[index]["file_id"] as? String != nil && !((dataMessages[index]["file_id"] as? String)!.isEmpty) {
                    Download().startHTTP(forKey: dataMessages[index]["file_id"]  as? String ?? "") { (name, progress) in
                        guard progress == 100 else {
                            return
                        }
                        DispatchQueue.main.async { [self] in
                            let section = dataDates.firstIndex(of: dataMessages[index]["chat_date"]  as? String ?? "")
                            let row = dataMessages.filter({$0["chat_date"]  as? String ?? "" == dataMessages[index]["chat_date"]  as? String ?? ""}).firstIndex(where: { $0["message_id"] as? String == message_id})
                            if row != nil && section != nil{
                                tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .automatic)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func sendTyping(l_pin: String, isTyping: Bool = false) {
        DispatchQueue.global().async {
            let tmessage = CoreMessage_TMessageBank.getUpdateTypingStatus(p_opposite: l_pin, p_scope: MessageScope.GROUP, p_status: isTyping ? "3": "4")
            _ = Nexilis.write(message: tmessage)
        }
    }
    
    private func checkNewMessage(tableView: UITableView) {
        currentIndexpath = tableView.indexPathsForVisibleRows?.last
        let indexFirst = tableView.indexPathsForVisibleRows?.first
        if indexFirst != nil {
            let dataMessages = dataMessages.filter({ $0["chat_date"]  as? String ?? "" == dataDates[indexFirst!.section] })
            if dataMessages.count == 0 {
                return
            }
            let contentHeight = tableView.contentSize.height
            let scrollViewHeight = tableView.frame.height
            let fullContentOffset = contentHeight - scrollViewHeight
            let contentOffsetY = tableView.contentOffset.y
            if ((currentIndexpath!.section == dataDates.count - 1 && indexFirst!.row != dataMessages.count - 1) || indexFirst!.section != dataDates.count - 1) && fullContentOffset - contentOffsetY > 100 {
                if !buttonScrollToBottom.isDescendant(of: self.view) {
                    addButtonScrollToBottom()
                    addCounterAtButttonScrollToBottom()
                }
            } else if (indexFirst!.section == dataDates.count - 1 && indexFirst!.row == dataMessages.count - 1) || fullContentOffset - contentOffsetY < 50 {
                if buttonScrollToBottom.isDescendant(of: self.view) {
                    buttonScrollToBottom.removeConstraints(buttonScrollToBottom.constraints)
                    buttonScrollToBottom.removeFromSuperview()
                    if indicatorCounterBSTB.isDescendant(of: self.view) {
                        indicatorCounterBSTB.removeConstraints(indicatorCounterBSTB.constraints)
                        indicatorCounterBSTB.removeFromSuperview()
                    }
                }
            }
            let indexPathFirst = tableChatView.indexPathsForVisibleRows?.first
            if indexPathFirst != nil && listViewOnSection.count != 0 && listViewOnSection.count - 1 >= indexPathFirst!.section {
                let headerView = listViewOnSection[indexPathFirst!.section]
                if headerView.isHidden {
                    headerView.isHidden = false
                }
            }
            if dataMessages.count - 1 < currentIndexpath!.row {
                return
            }
            var listData = dataMessages[0...currentIndexpath!.row]
            listData = listData.filter({$0["status"]  as? String ?? "" != "4" && $0["status"]  as? String ?? "" != "8"})
            if listData.count != 0 {
                let idMe = User.getMyPin() as String?
                for i in 0...listData.count - 1 {
                    if listData[i]["f_pin"] as? String != idMe {
                        sendReadMessageStatus(chat_id: self.dataTopic["chat_id"]  as? String ?? "", f_pin: listData[i]["f_pin"]  as? String ?? "", message_scope_id: MessageScope.GROUP, message_id: listData[i]["message_id"]  as? String ?? "")
                    }
                }
            }
        }
        if counter == 0 && indicatorCounterBSTB.isDescendant(of: self.view) {
            indicatorCounterBSTB.removeConstraints(indicatorCounterBSTB.constraints)
            indicatorCounterBSTB.removeFromSuperview()
        } else if counter != 0 && currentIndexpath != nil {
            let dataFilter = dataMessages.filter({ $0["chat_date"]  as? String ?? "" == dataDates[currentIndexpath!.section] })
            if dataFilter.count == 0 {
                return
            }
            let idx = dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == dataFilter[currentIndexpath!.row]["message_id"]  as? String ?? ""})
            if idx == nil {
                return
            }
            if (dataMessages.count - counter) <= idx! {
                let countUpdate = idx! - (dataMessages.count - counter)
                counter = counter - (countUpdate + 1)
                if indicatorCounterBSTB.isDescendant(of: self.view) {
                    labelCounter.text = "\(counter)"
                }
                updateCounter(counter: counter)
            }
        }
    }
}

extension EditorGroup: ImageVideoPickerDelegate, PreviewAttachmentImageVideoDelegate, PHPickerViewControllerDelegate {
    public func didSelect(imagevideo: Any?) {
        if (imagevideo != nil) {
            let imageVideoData = imagevideo as! [UIImagePickerController.InfoKey: Any]
            let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
            previewImageVC.imageVideoData = imageVideoData
            if (textFieldSend.textColor != .lightGray) {
                previewImageVC.currentTextTextField = textFieldSend.text
            }
            previewImageVC.modalPresentationStyle = .custom
            previewImageVC.delegate = self
            previewImageVC.isGroup = true
            previewImageVC.isAck = self.isAck
            previewImageVC.isConfidential = self.isConfidential
            self.present(previewImageVC, animated: true, completion: nil)
        }
    }
    
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        if !isBlackCancelButton {
            let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
            UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes , for: .normal)
        }
        guard let result = results.first else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        if result.itemProvider.hasItemConformingToTypeIdentifier("com.compuserve.gif") {
            picker.dismiss(animated: true, completion: {
                Nexilis.showLoader(text: "Preparing...".localized())
                result.itemProvider.loadDataRepresentation(forTypeIdentifier: "com.compuserve.gif") { data, error in
                    if error != nil {
                        self.loadAnimatedMedia(from: result.itemProvider) { data, isGIF in
                            guard let data = data else {
                                print("Failed to load media")
                                return
                            }

                            DispatchQueue.main.async {
                                Nexilis.hideLoader() {
                                    let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
                                    if (self.textFieldSend.textColor != .lightGray) {
                                        previewImageVC.currentTextTextField = self.textFieldSend.text
                                    }
                                    if isGIF {
                                        previewImageVC.fromCopy = true
                                        previewImageVC.isGIF = true
                                        previewImageVC.dataGIF = data
                                        previewImageVC.modalPresentationStyle = .custom
                                        previewImageVC.delegate = self
                                        previewImageVC.isAck = self.isAck
                                        previewImageVC.isConfidential = self.isConfidential
                                    } else {
                                        let fileManager = FileManager.default
                                        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                                        let destinationURL = documentsDirectory.appendingPathComponent(UUID().uuidString + ".mov")
                                        do {
                                            try data.write(to: destinationURL)
                                            previewImageVC.modalPresentationStyle = .custom
                                            previewImageVC.urlVideoPhpPicker = destinationURL
                                            previewImageVC.delegate = self
                                            previewImageVC.isAck = self.isAck
                                            previewImageVC.isConfidential = self.isConfidential
                                        } catch {
                                            
                                        }
                                    }
                                    self.present(previewImageVC, animated: true, completion: nil)
                                }
                            }
                        }
                    } else if let data = data {
                        DispatchQueue.main.async {
                            Nexilis.hideLoader() {
                                let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
                                if (self.textFieldSend.textColor != .lightGray) {
                                    previewImageVC.currentTextTextField = self.textFieldSend.text
                                }
                                previewImageVC.fromCopy = true
                                previewImageVC.isGIF = true
                                previewImageVC.dataGIF = data
                                previewImageVC.modalPresentationStyle = .custom
                                previewImageVC.delegate = self
                                previewImageVC.isAck = self.isAck
                                previewImageVC.isConfidential = self.isConfidential
                                self.present(previewImageVC, animated: true, completion: nil)
                            }
                        }
                    }
                }
            })
        } else if result.itemProvider.hasItemConformingToTypeIdentifier("public.image") {
            picker.dismiss(animated: true, completion: {
                Nexilis.showLoader(text: "Preparing...".localized())
                result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, error in
                    if let data = data {
                        do {
                            DispatchQueue.main.async {
                                Nexilis.hideLoader {
                                    let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
                                    if (self.textFieldSend.textColor != .lightGray) {
                                        previewImageVC.currentTextTextField = self.textFieldSend.text
                                    }
                                    previewImageVC.fromCopy = true
                                    previewImageVC.image = UIImage(data: data)
                                    previewImageVC.modalPresentationStyle = .custom
                                    previewImageVC.delegate = self
                                    previewImageVC.isAck = self.isAck
                                    previewImageVC.isConfidential = self.isConfidential
                                    self.present(previewImageVC, animated: true, completion: nil)
                                }
                            }
                        } catch {
                            print("Error loading image data: \(error)")
                        }
                    } else {
                        print("Error: \(String(describing: error))")
                    }
                }
            })
        } else if result.itemProvider.hasItemConformingToTypeIdentifier("public.movie") {
            picker.dismiss(animated: true, completion: {
                Nexilis.showLoader(text: "Preparing...".localized())
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { url, error in
                    if let url = url {
                        let fileManager = FileManager.default
                        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                        var nameFile = url.lastPathComponent
                        if nameFile.contains("&uuid"){
                            nameFile = UUID().uuidString + ".mov"
                        }
                        let destinationURL = documentsDirectory.appendingPathComponent(nameFile)
                        do {
                            if fileManager.fileExists(atPath: destinationURL.path) {
                                try fileManager.removeItem(at: destinationURL)
                            }
                            try fileManager.copyItem(at: url, to: destinationURL)
                            DispatchQueue.main.async {
                                Nexilis.hideLoader {
                                    let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
                                    if (self.textFieldSend.textColor != .lightGray) {
                                        previewImageVC.currentTextTextField = self.textFieldSend.text
                                    }
                                    previewImageVC.modalPresentationStyle = .custom
                                    previewImageVC.urlVideoPhpPicker = destinationURL
                                    previewImageVC.delegate = self
                                    previewImageVC.isAck = self.isAck
                                    previewImageVC.isConfidential = self.isConfidential
                                    self.present(previewImageVC, animated: true, completion: nil)
                                }
                            }
                        } catch {
                            print("Error copying video file: \(error.localizedDescription)")
                        }
                    }
                }
            })
        }
    }
    
    func loadAnimatedMedia(from provider: NSItemProvider, completion: @escaping (Data?, Bool) -> Void) {
        // First: real GIF
        if provider.hasItemConformingToTypeIdentifier("com.compuserve.gif") {
            provider.loadFileRepresentation(forTypeIdentifier: "com.compuserve.gif") { url, error in
                if let url = url, let data = try? Data(contentsOf: url) {
                    completion(data, true) // true = isGIF
                } else {
                    // fallback
                    self.loadQuickTimeMovie(from: provider, completion: completion)
                }
            }
        } else {
            // fallback directly
            self.loadQuickTimeMovie(from: provider, completion: completion)
        }
    }

    private func loadQuickTimeMovie(from provider: NSItemProvider, completion: @escaping (Data?, Bool) -> Void) {
        if provider.hasItemConformingToTypeIdentifier("com.apple.quicktime-movie") {
            provider.loadFileRepresentation(forTypeIdentifier: "com.apple.quicktime-movie") { url, error in
                if let url = url, let data = try? Data(contentsOf: url) {
                    completion(data, false) // false = it's MOV, not GIF
                } else {
                    completion(nil, false)
                }
            }
        } else {
            completion(nil, false)
        }
    }
    
    func sendChatFromPreviewImage(message_text: String, attachment_flag: String, image_id: String, video_id: String, thumb_id: String, gif_id: String, viewController: UIViewController, specFile: String) {
        specFileString = specFile
        sendChat(message_text: message_text, attachment_flag: attachment_flag, image_id: image_id, video_id: video_id, thumb_id: thumb_id, viewController: viewController, gif_id: gif_id)
    }
}

extension EditorGroup: UIDocumentPickerDelegate, DocumentPickerDelegate, QLPreviewControllerDataSource {
    public func didSelectDocument(document: Any?) {
        if (document != nil) {
            self.previewItem = (document as! [URL])[0] as NSURL
            let previewController = QLPreviewController()
            previewController.dataSource = self
            let vcHandleFile = UIViewController()
            let nc = UINavigationController(rootViewController: vcHandleFile)
            let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            let navBarAppearance = UINavigationBarAppearance()
            nc.defaultStyle()
            nc.modalPresentationStyle = .pageSheet
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
            navBarAppearance.titleTextAttributes = attributes
            nc.navigationBar.standardAppearance = navBarAppearance
            nc.navigationBar.scrollEdgeAppearance = navBarAppearance
            let backButton = navigationQLPreviewDocument(title: "Cancel".localized(), style: .plain, target: self, action: #selector(cancelDocumentPreview))
            vcHandleFile.navigationItem.leftBarButtonItem = backButton
            let sendButton = navigationQLPreviewDocument(title: "Send".localized(), style: .done, target: self, action: #selector(sendDocument))
            buttonSpec.setImage(UIImage(named: "pb_ic_attach_spc_off", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal).resize(target: CGSize(width: 30, height: 30)), for: .normal)
            buttonSpec.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            buttonSpec.addTarget(self, action: #selector(showConfigurationFile), for: .touchUpInside)
            let barButtonItemSpec = UIBarButtonItem(customView: buttonSpec)
            vcHandleFile.navigationItem.rightBarButtonItems = [sendButton, barButtonItemSpec]
            backButton.navigation = nc
            sendButton.navigation = nc
            if let viewVc = vcHandleFile.view {
                vcHandleFile.title = self.previewItem?.lastPathComponent
                vcHandleFile.addChild(previewController)
                previewController.dataSource = self
                previewController.view.frame = CGRect(x: 0, y: 0, width: viewVc.bounds.size.width, height: viewVc.bounds.size.height)
                previewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                viewVc.addSubview(previewController.view)
                previewController.didMove(toParent: vcHandleFile)
                
                self.present(nc, animated: true)
            }
        }
    }
    
    @objc private func showConfigurationFile() {
        let modalVC = UIViewController()
        if let viewModal = modalVC.view {
            viewModal.backgroundColor = .whiteBubbleColor
            
            let closeButton = UIButton(type: .close)
            viewModal.addSubview(closeButton)
            closeButton.anchor(top: viewModal.topAnchor, right: viewModal.rightAnchor, paddingTop: 15, paddingRight: 15, width: 30, height: 30)
            closeButton.layer.cornerRadius = 15
            closeButton.clipsToBounds = true
            closeButton.backgroundColor = .lightGray.withAlphaComponent(0.1)
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
            closeButton.addAction(UIAction { _ in
                modalVC.dismiss(animated: true)
            }, for: .touchUpInside)
            
            let imageSpec = UIButton(type: .custom)
            viewModal.addSubview(imageSpec)
            imageSpec.anchor(top: viewModal.topAnchor, left: viewModal.leftAnchor, paddingTop: 25, paddingLeft: 15, width: 40, height: 40)
            imageSpec.layer.cornerRadius = 20
            imageSpec.clipsToBounds = true
            imageSpec.backgroundColor = .lightGray.withAlphaComponent(0.1)
            imageSpec.setImage(UIImage(named: "pb_ic_attach_spc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal).resize(target: CGSize(width: 35, height: 35)), for: .normal)
            
            let title = UILabel()
            title.text = "Option for Attachment".localized()
            viewModal.addSubview(title)
            title.anchor(top: viewModal.topAnchor, left: imageSpec.rightAnchor, paddingTop: 23, paddingLeft: 10)
            title.textColor = .label
            title.font = .boldSystemFont(ofSize: 16)
            
            let subtitle = UILabel()
            subtitle.text = "Select option :".localized()
            viewModal.addSubview(subtitle)
            subtitle.anchor(top: title.bottomAnchor, left: imageSpec.rightAnchor, paddingLeft: 10)
            subtitle.textColor = .gray
            subtitle.font = .systemFont(ofSize: 14)
            
            tableViewConfigFile = UITableView()
            viewModal.addSubview(tableViewConfigFile)
            tableViewConfigFile.backgroundColor = .white
            tableViewConfigFile.layer.cornerRadius = 8.0
            tableViewConfigFile.clipsToBounds = true
            tableViewConfigFile.anchor(top: imageSpec.bottomAnchor, left: viewModal.leftAnchor, bottom: viewModal.bottomAnchor, right: viewModal.rightAnchor, paddingTop: 15, paddingLeft: 15, paddingBottom: 80, paddingRight: 15)
            tableViewConfigFile.register(UITableViewCell.self, forCellReuseIdentifier: "cellConfigFile")
            tableViewConfigFile.dataSource = self
            tableViewConfigFile.delegate = self
            tableViewConfigFile.separatorStyle = .singleLine
            tableViewConfigFile.tableFooterView = UIView()
            if #available(iOS 15.0, *) {
                tableViewConfigFile.sectionHeaderTopPadding = 0
            }
            
            if #available(iOS 15.0, *) {
                if let sheet = modalVC.sheetPresentationController {
                    sheet.detents = [.medium()]
                }
            } else {
                // Fallback on earlier versions
            }
        }
        UIApplication.shared.visibleViewController?.present(modalVC, animated: true)
    }
    
    @objc private func cancelDocumentPreview(sender: navigationQLPreviewDocument) {
        sender.navigation.dismiss(animated: true, completion: nil)
    }
    
    @objc private func sendDocument(sender: navigationQLPreviewDocument) {
        DispatchQueue.global().async {
            if Nexilis.checkingAccess(key: "content_inspection") {
                DispatchQueue.main.async {
                    Nexilis.showLoader(text: "Scanning File...".localized())
                }
                let result = (self.previewItem! as URL).validateFile()
                DispatchQueue.main.async {
                    Nexilis.hideLoader {
                        sender.navigation.dismiss(animated: true, completion: {
                            if result == 1 {
                                sendIt()
                            } else {
                                APIS.showWarningFile(type: result)
                            }
                        })
                    }
                }
            } else {
                DispatchQueue.main.async {
                    sendIt()
                }
            }
            
            func sendIt() {
                sender.navigation.dismiss(animated: true, completion: nil)

                guard let previewItem = self.previewItem else { return }
                guard var dataFile = try? Data(contentsOf: previewItem as URL) else { return }

                func sanitizeFile(mimeType: String, sanitizeAction: (Data) -> MessageGuardLite.Result) -> Data? {
                    DispatchQueue.main.async {
                        Nexilis.showLoader(text: "Sanitizing your \(mimeType.contains("pdf") ? "pdf file" : "image") (Message Guard)".localized())
                    }
                    let res = sanitizeAction(dataFile)
                    defer {
                        DispatchQueue.main.async { Nexilis.hideLoader {} }
                    }

                    if res.verdict == .block {
                        DispatchQueue.main.async {
                            Nexilis.hideLoader {
                                APIS.showMessageGuardFile(mime: res.mime)
                            }
                        }
                        return nil
                    }
                    return res.data ?? Data()
                }

                func processIt(with data: Data) {
                    guard let urlFile = self.previewItem?.absoluteString else { return }
                    let originalFileName = (urlFile as NSString).lastPathComponent.removingPercentEncoding ?? "file"
                    let renamedNameFile = "Nexilis_\(Date().currentTimeMillis())_\(originalFileName)"

                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let fileURL = documentsDirectory.appendingPathComponent(renamedNameFile)

                    if !FileManager.default.fileExists(atPath: fileURL.path) {
                        try? data.write(to: fileURL)
                    }

                    DispatchQueue.main.async {
                        self.sendChat(
                            message_text: "\(originalFileName)|",
                            attachment_flag: "6",
                            file_id: renamedNameFile,
                            viewController: self
                        )
                    }
                }

                if Nexilis.checkingAccess(key: "message_guard") {
                    DispatchQueue.global().async {
                        let guardLite = MessageGuardLite(limits: .defaults())
                        let mimeType = MessageGuardLite.sniffMime(dataFile)

                        if mimeType == "image/png" || mimeType == "image/jpeg" {
                            if let sanitized = sanitizeFile(mimeType: mimeType, sanitizeAction: guardLite.sanitizeImage) {
                                dataFile = sanitized
                            } else { return }
                        } else if mimeType == "application/pdf" {
                            if let sanitized = sanitizeFile(mimeType: mimeType, sanitizeAction: guardLite.sanitizePdf) {
                                dataFile = sanitized
                            } else { return }
                        }

                        processIt(with: dataFile)
                    }
                } else {
                    processIt(with: dataFile)
                }
            }
        }
    }
}

extension EditorGroup: UITextViewDelegate, CustomTextViewPasteDelegate {
    func customTextViewDidPasteText(image: UIImage?, dataGIF: Data?) {
        let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
        previewImageVC.image = image
        previewImageVC.isGIF = image == nil
        previewImageVC.fromCopy = true
        previewImageVC.dataGIF = dataGIF
        previewImageVC.currentTextTextField = textFieldSend.text
        previewImageVC.modalPresentationStyle = .custom
        previewImageVC.delegate = self
        previewImageVC.isAck = self.isAck
        previewImageVC.isConfidential = self.isConfidential
        self.present(previewImageVC, animated: true, completion: nil)
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        lastPositionCursorMention = textView.selectedRange.location
        var isShowMention = false

        let fulltextForMention = textView.text.prefix(lastPositionCursorMention)
        
        let lines = fulltextForMention.split(separator: "\n")
        if let lastLineIndex = lines.lastIndex(where: { !$0.isEmpty }) {
            let words = lines[lastLineIndex].split(separator: " ")
            if let lastWordIndex = words.lastIndex(where: { !$0.isEmpty }) {
                let mentionText = words[lastWordIndex]
                let lastChar = fulltextForMention.last
                if lastChar != "\n" && lastChar != " " {
                    if mentionText.starts(with: "@") || (mentionText.count >= 2 && (self.textFieldSend.textColor != UIColor.lightGray || heightTableEditMention != nil) && extractFromAtIfSymbolsBefore(String(mentionText)) == nil) {
                        showMention(text: mentionText.starts(with: "@") ? String(mentionText.dropFirst()) : String(mentionText))
                        isShowMention = true
                    } else if let textM = extractFromAtIfSymbolsBefore(String(mentionText)) {
                        showMention(text: String(textM.dropFirst()))
                        isShowMention = true
                    }
                }
            }
        }
        
        if !isShowMention {
            hideMention()
        }

        if var nowTextFieldSend = self.textFieldSend {
            if isEditingMessage {
                nowTextFieldSend = editTextView
            }
            if let sr = nowTextFieldSend.selectedTextRange {
                if let fnt = nowTextFieldSend.font {
                    let cursorPosition = textView.caretRect(for: sr.start).origin
                    let doubleCurrentLine = cursorPosition.y / fnt.lineHeight
                    if doubleCurrentLine.isFinite {
                        let currentLine = Int(ceil(doubleCurrentLine))
                        UIView.animate(withDuration: 0.3) {
                            let layoutManager = textView.layoutManager
                            var numberOfLines = 0
                            var index = 0
                            let numberOfGlyphs = layoutManager.numberOfGlyphs

                            while index < numberOfGlyphs {
                                var lineRange = NSRange()
                                layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
                                index = NSMaxRange(lineRange)
                                numberOfLines += 1
                            }
                            if currentLine == 1 && (numberOfLines == 1 || numberOfLines == 0) {
                                if self.isEditingMessage {
                                    self.constraintHeighteditTextView.constant = 40
                                } else {
                                    self.heightTextFieldSend.constant = 40
                                }
                            } else if (self.heightTextFieldSend.constant < 95.0 || (self.constraintHeighteditTextView != nil && self.constraintHeighteditTextView.constant < 95.0)) && currentLine >= 4 {
                                if self.isEditingMessage {
                                    self.constraintHeighteditTextView.constant = 95.0
                                } else {
                                    self.heightTextFieldSend.constant = 95.0
                                }
                            } else if currentLine < 4 && numberOfLines < 5 {
                                if (nowTextFieldSend.text.count > 0 && self.heightTextFieldSend.constant != nowTextFieldSend.contentSize.height) {
                                    if self.isEditingMessage {
                                        self.constraintHeighteditTextView.constant = nowTextFieldSend.contentSize.height
                                    } else {
                                        self.heightTextFieldSend.constant = nowTextFieldSend.contentSize.height
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if self.isEditingMessage && textView == editTextView {
            if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                buttonSendEdit.isEnabled = false
            } else if !buttonSendEdit.isEnabled {
                buttonSendEdit.isEnabled = true
            }
        }
        
        //indention code:
        let text = textView.text ?? ""
        let cursorLocation = textView.selectedRange.location

        // Find current line range where cursor is
        if let lineRange = (text as NSString).lineRange(for: NSRange(location: cursorLocation, length: 0)) as NSRange? {
            let line = (text as NSString).substring(with: lineRange)

            // Detect bullet ("  •") or numbered ("  1.") list
            if line.hasPrefix("  •") || line.range(of: #"^\s{2}\d+\."#, options: .regularExpression) != nil {
                var bulletEnd = lineRange.location + 2
                if !line.hasPrefix("  •") {
                    bulletEnd = lineRange.location + 3
                }

                // Prevent cursor before bullet/number
                if cursorLocation < bulletEnd {
                    DispatchQueue.main.async {
                        textView.selectedRange = NSRange(location: bulletEnd, length: 0)
                    }
                }
            }
        }
    }
    
    func extractFromAtIfSymbolsBefore(_ text: String) -> String? {
        guard let atIndex = text.firstIndex(of: "@") else {
            return nil
        }
        
        let beforeAt = text[..<atIndex]
        let afterAt = text[atIndex...]

        // Define symbols as anything that's not a letter or digit
        let symbolSet = CharacterSet.letters.union(.decimalDigits).inverted
        let isAllSymbols = beforeAt.unicodeScalars.allSatisfy { symbolSet.contains($0) }

        return isAllSymbols ? String(afterAt) : nil
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        if textView.text.count == 0 {
            isAlwaysHideLinkPreview = false
        }
        if allowTyping {
            allowTyping = false
            if dataTopic["chat_id"]  as? String ?? "" == "" {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [dataGroup["group_id"]  as? String ?? ""])
                sendTyping(l_pin: dataGroup["group_id"]  as? String ?? "")
            } else {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [dataTopic["chat_id"]  as? String ?? ""])
                sendTyping(l_pin: dataTopic["chat_id"]  as? String ?? "")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: {
                self.allowTyping = true
            })
        }
        timerCheckLink?.invalidate()
        timerCheckLink = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {_ in
            self.checkLink(fullText: textView.text)
        })
        
        //indention code:
        let text = textView.text ?? ""
        let cursorPosition = textView.selectedRange.location
        
        let tempListMention = listMentionInTextField
        if listMentionInTextField.count > 0 {
            for j in 0..<listMentionInTextField.count {
                var index = j
                if tempListMention.count != listMentionInTextField.count {
                    index = j - (tempListMention.count - listMentionInTextField.count)
                }
                var upper = (Int(listMentionInTextField[index].ex_block ?? "0") ?? 0)
                if cursorPosition <= upper {
                    upper += text.count - lastTextLength
                    listMentionInTextField[index].ex_block = "\(upper)"
                }
                let lower = upper - listMentionInTextField[index].fullName.count
                let name = listMentionInTextField[index].fullName.trimmingCharacters(in: .whitespaces)
                if textView.text.substring(from: lower, to: upper) != "@\(name)" {
                    listMentionInTextField.remove(at: index)
                }
            }
        }
        
        // Handle Bullets (- [space] + letter → • )
        let bulletPattern = #"(?<=\n|^)- (\S)"#
        if let match = text.range(of: bulletPattern, options: .regularExpression) {
            let matchedText = text[match]

            if let spaceIndex = matchedText.firstIndex(of: " ") {
                let firstLetter = matchedText[matchedText.index(after: spaceIndex)...]
                let replacedText = text.replacingOccurrences(of: matchedText, with: "  • \(firstLetter)", range: match)

                let newCursorPosition = cursorPosition + 2  // Adjust cursor position
                textView.text = replacedText
                DispatchQueue.main.async {
                    textView.selectedRange = NSRange(location: newCursorPosition, length: 0)
                }
            }
        }

        // Handle Numbered Lists (e.g., "1. " [space] + letter → " 1.")
        let numberPattern = #"(?<=\n|^)(\d+)\. (\S)"# // Matches "1. X"
        if let match = text.range(of: numberPattern, options: .regularExpression) {
            let matchedText = text[match]

            let replacedText = text.replacingOccurrences(of: matchedText, with: "  \(matchedText)", range: match)

            let newCursorPosition = cursorPosition + 2  // Adjust cursor
            textView.text = replacedText
            DispatchQueue.main.async {
                textView.selectedRange = NSRange(location: newCursorPosition, length: 0)
            }
        }

        handleRichText(textView)
        lastTextLength = text.count
    }
    
    private func showMention(text: String) {
        if self.contraintBottomMention.constant < 0 {
            if !isEditingMessage {
                self.contraintBottomMention.constant = 25 + constraintBottomAttachment.constant + self.heightTextFieldSend.constant + self.viewTextfield.bounds.height
                UIView.animate(withDuration: 0.5, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }
        listMentionWithText.removeAll()
        Database.shared.database?.inTransaction({ fmdb, rollback in
            do {
                let idMe = User.getMyPin()!
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_pin, first_name || ' ' || ifnull(last_name, '') name FROM GROUPZ_MEMBER where group_id='\(self.dataGroup["group_id"]  as? String ?? "")' AND f_pin <> '\(idMe)' AND name LIKE '%\(text)%'") {
                    while cursor.next() {
                        let user = User(pin: "")
                        user.pin = cursor.string(forColumnIndex: 0) ?? ""
                        user.firstName = cursor.string(forColumnIndex: 1) ?? ""
                        if !user.pin.isEmpty {
                            let userFromBuddy = User.getDataCanNil(pin: user.pin, fmdb: fmdb)
                            if userFromBuddy != nil {
                                listMentionWithText.append(userFromBuddy!)
                            } else {
                                listMentionWithText.append(user)
                            }
                        }
                    }
                    if Utils.getGPTBotName().lowercased().contains(text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let gptUser = User(pin: "-997",
                                        firstName: Utils.getGPTBotName(),
                                        lastName: "",
                                        thumb: "",
                                        userType: "0",
                                        official: "1")
                        listMentionWithText.insert(gptUser, at: 0)
                    }
                    cursor.close()
                }
                listMentionWithText.removeAll(where: { listMentionInTextField.contains($0) })
                var nowTableMention = tableMention!
                var nowHeightTableMention = heightTableMention!
                if isEditingMessage {
                    nowTableMention = tableMentionEdit
                    if heightTableEditMention != nil {
                        nowHeightTableMention = heightTableEditMention
                    } else {
                        return
                    }
                }
                if listMentionWithText.count > 0 {
                    if listMentionWithText.count < 5 {
                        nowHeightTableMention.constant = CGFloat(44 * listMentionWithText.count)
                    } else {
                        nowHeightTableMention.constant = 44 * 4
                    }
                    nowTableMention.reloadData()
                } else {
                    nowHeightTableMention.constant = 44
                    self.hideMention()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    private func hideMention() {
        if self.contraintBottomMention.constant > 0 {
            listMentionWithText.removeAll()
            tableMention.reloadData()
            self.contraintBottomMention.constant = 0 - self.heightTableMention.constant
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded()
            })
        } else if self.heightTableEditMention != nil && self.heightTableEditMention.constant != 0 {
            listMentionWithText.removeAll()
            tableMentionEdit.reloadData()
            self.heightTableEditMention.constant = 0
        }
    }
    
    private func checkLink(fullText: String) {
        if !isAlwaysHideLinkPreview {
            var text = ""
            let listTextSplitBreak = fullText.components(separatedBy: "\n")
            let indexFirstLinkSplitBreak = listTextSplitBreak.firstIndex(where: { $0.contains("www.") || $0.contains("http://") || $0.contains("https://") })
            if indexFirstLinkSplitBreak != nil {
                let listTextSplitSpace = listTextSplitBreak[indexFirstLinkSplitBreak!].components(separatedBy: " ")
                let indexFirstLinkSplitSpace = listTextSplitSpace.firstIndex(where: { ($0.starts(with: "www.") && $0.components(separatedBy: ".").count > 2) || ($0.starts(with: "http://") && $0.components(separatedBy: ".").count > 1) || ($0.starts(with: "https://") && $0.components(separatedBy: ".").count > 1) })
                if indexFirstLinkSplitSpace != nil {
                    text = listTextSplitSpace[indexFirstLinkSplitSpace!]
                }
            }
            if !text.isEmpty {
                var stringURl = text
                if stringURl.starts(with: "www.") {
                    stringURl = "https://" + stringURl.replacingOccurrences(of: "www.", with: "")
                }
                var dataURL = ""
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select data_link from LINK_PREVIEW where link='\(text)'") {
                            while cursor.next() {
                                if let data = cursor.string(forColumnIndex: 0) {
                                    dataURL = data
                                }
                            }
                            cursor.close()
                        }
                    } catch {
                        rollback.pointee = true
                        print("Access database error: \(error.localizedDescription)")
                    }
                })
                if !dataURL.isEmpty {
                    if let data = try! JSONSerialization.jsonObject(with: dataURL.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                        let imageUrl = data["imageUrl"] as? String
                        let link = data["link"]  as? String ?? ""
                        if imageUrl == nil || (link.contains("youtube.com") && link.contains("watch?v=") && !imageUrl!.contains("img.youtube.com/vi/")) {
                            dataURL = ""
                        }
                    }
                }
                if !dataURL.isEmpty {
                    if let data = try! JSONSerialization.jsonObject(with: dataURL.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                        let title = data["title"]  as? String ?? ""
                        let description = data["description"]  as? String ?? ""
                        let imageUrl = data["imageUrl"] as? String
                        if self.showingLink != text {
                            self.showingLink = text
                            self.deleteLinkPreview()
                            if !textFieldSend.text.isEmpty || textFieldSend.text.contains(text){
                                self.buildPreviewLink(imageUrl: imageUrl, title: title, description: description, stringURl: text)
                            }
                        }
                    }
                } else {
                    let urlConfig = URLSessionConfiguration.default
                    let sessionDelegate = SelfSignedURLSessionDelegate()
                    let session = URLSession(configuration: urlConfig, delegate: sessionDelegate, delegateQueue: nil)
                    let slp = SwiftLinkPreview(session: session,
                                   workQueue: SwiftLinkPreview.defaultWorkQueue,
                                   responseQueue: DispatchQueue.main,
                                       cache: DisabledCache.instance)
                    let preview = slp.preview(stringURl,
                                              onSuccess: { result in
                        let title = result.title?.trimmingCharacters(in: .whitespacesAndNewlines)
                                    .nilIfEmpty ?? URL(string: text)?.host ?? "Untitled"
                        let description: String
                        if text.contains("google.com") {
                            description = "" // special rule for google
                        } else {
                            description = result.description?.trimmingCharacters(in: .whitespacesAndNewlines)
                                .nilIfEmpty ?? ""
                        }
                        let imageUrl = self.youtubeThumbnail(from: text)
                            ?? result.image
                            ?? result.icon
                            ?? ""
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                var dataJson: [String: Any] = [:]
                                dataJson["title"] = title
                                dataJson["description"] = description
                                dataJson["imageUrl"] = imageUrl
                                dataJson["link"] = text
                                guard let json = String(data: try! JSONSerialization.data(withJSONObject: dataJson, options: []), encoding: String.Encoding.utf8) else {
                                    return
                                }
                                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "LINK_PREVIEW", cvalues: [
                                    "id" : "\(Date().currentTimeMillis().toHex())",
                                    "link" : text,
                                    "data_link" : json,
                                    "retry": 0
                                ], replace: true)
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                        if self.showingLink != text {
                            self.showingLink = text
                            self.deleteLinkPreview()
                            if !self.textFieldSend.text.isEmpty || self.textFieldSend.text.contains(text){
                                self.buildPreviewLink(imageUrl: imageUrl, title: title, description: description, stringURl: text)
                            }
                        }
                    },
                    onError: { error in
                        self.deleteLinkPreview()
                    })
                }
            } else {
                deleteLinkPreview()
            }
        }
    }
    
    private func buildPreviewLink(imageUrl: String?, title: String, description: String?, stringURl: String) {
        if !self.viewTextfield.subviews.contains(self.containerLink){
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                self.constraintTopTextField.constant = self.constraintTopTextField.constant + 80
                if self.contraintBottomMention.constant > 0 {
                    self.contraintBottomMention.constant = self.contraintBottomMention.constant + 80 + self.heightTextFieldSend.constant
                }
            }, completion: nil)
        }
        
        self.viewTextfield.addSubview(self.containerLink)
        self.containerLink.translatesAutoresizingMaskIntoConstraints = false
        self.containerLink.leadingAnchor.constraint(equalTo: self.viewTextfield.leadingAnchor).isActive = true
        self.containerLink.bottomAnchor.constraint(equalTo: self.textFieldSend.topAnchor).isActive = true
        self.containerLink.trailingAnchor.constraint(equalTo: self.viewTextfield.trailingAnchor).isActive = true
        self.containerLink.heightAnchor.constraint(equalToConstant: 80.0).isActive = true
        self.containerLink.backgroundColor = .secondaryColor
        
        if self.reffId != nil {
            self.bottomAnchorPreviewReply.isActive = false
            self.bottomAnchorPreviewReply = self.containerPreviewReply.bottomAnchor.constraint(equalTo: self.containerLink.topAnchor)
            self.bottomAnchorPreviewReply.isActive = true
        }
        
        let imagePreview = UIImageView()
        if imageUrl != nil {
            self.containerLink.addSubview(imagePreview)
            imagePreview.translatesAutoresizingMaskIntoConstraints = false
            imagePreview.leadingAnchor.constraint(equalTo: self.containerLink.leadingAnchor).isActive = true
            imagePreview.bottomAnchor.constraint(equalTo: self.containerLink.bottomAnchor).isActive = true
            imagePreview.topAnchor.constraint(equalTo: self.containerLink.topAnchor).isActive = true
            imagePreview.widthAnchor.constraint(equalToConstant: 80.0).isActive = true
            imagePreview.loadImageAsync(with: imageUrl)
            imagePreview.contentMode = .scaleAspectFit
        }
        
        let titlePreview = UILabel()
        self.containerLink.addSubview(titlePreview)
        titlePreview.translatesAutoresizingMaskIntoConstraints = false
        if imageUrl != nil {
            titlePreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
        } else {
            titlePreview.leadingAnchor.constraint(equalTo: self.containerLink.leadingAnchor, constant: 5.0).isActive = true
        }
        titlePreview.topAnchor.constraint(equalTo: self.containerLink.topAnchor, constant: 25.0).isActive = true
        titlePreview.trailingAnchor.constraint(equalTo: self.containerLink.trailingAnchor, constant: -80.0).isActive = true
        titlePreview.text = title
        titlePreview.font = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        titlePreview.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        
        let descPreview = UILabel()
        self.containerLink.addSubview(descPreview)
        descPreview.translatesAutoresizingMaskIntoConstraints = false
        if imageUrl != nil {
            descPreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
        } else {
            descPreview.leadingAnchor.constraint(equalTo: self.containerLink.leadingAnchor, constant: 5.0).isActive = true
        }
        descPreview.topAnchor.constraint(equalTo: titlePreview.bottomAnchor).isActive = true
        descPreview.trailingAnchor.constraint(equalTo: self.containerLink.trailingAnchor, constant: -80.0).isActive = true
        descPreview.text = description
        descPreview.font = UIFont.systemFont(ofSize: 12.0 + offset())
        descPreview.textColor = .gray
        descPreview.numberOfLines = 1
        
        let linkPreview = UILabel()
        self.containerLink.addSubview(linkPreview)
        linkPreview.translatesAutoresizingMaskIntoConstraints = false
        if imageUrl != nil {
            linkPreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
        } else {
            linkPreview.leadingAnchor.constraint(equalTo: self.containerLink.leadingAnchor, constant: 5.0).isActive = true
        }
        linkPreview.topAnchor.constraint(equalTo: descPreview.bottomAnchor).isActive = true
        linkPreview.trailingAnchor.constraint(equalTo: self.containerLink.trailingAnchor, constant: -80.0).isActive = true
        linkPreview.text = stringURl
        linkPreview.font = UIFont.systemFont(ofSize: 10.0 + offset())
        linkPreview.textColor = .gray
        linkPreview.numberOfLines = 1
        
        let cancelPreview = UIButton(type: .custom)
        self.containerLink.addSubview(cancelPreview)
        cancelPreview.translatesAutoresizingMaskIntoConstraints = false
        cancelPreview.trailingAnchor.constraint(equalTo: self.containerLink.trailingAnchor, constant: -10).isActive = true
        cancelPreview.centerYAnchor.constraint(equalTo: self.containerLink.centerYAnchor).isActive = true
        cancelPreview.setImage(UIImage(systemName: "xmark.circle" , withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default)), for: .normal)
        cancelPreview.addTarget(nil, action: #selector(self.removeLinkPreviewUntilEmptyTextView), for: .touchUpInside)
        cancelPreview.backgroundColor = .clear
        cancelPreview.tintColor = .mainColor
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black
        }
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty && textView != editTextView {
            textView.textColor = UIColor.lightGray
            textView.text = "Send message".localized()
        }
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.isEmpty {
            if listMentionInTextField.count > 0 {
                for i in 0..<listMentionInTextField.count {
                    if lastPositionCursorMention == Int(listMentionInTextField[i].ex_block!)! + 1 {
                        let fulltextForMention = textView.text.substring(from: 0, to: lastPositionCursorMention - 1)
                        let diff = textView.text.count - fulltextForMention.count
                        var text = textView.text ?? ""
                        let nameMention = listMentionInTextField[i].fullName.trimmingCharacters(in: .whitespaces)
                        let rangeReplacement = NSRange(location: lastPositionCursorMention - nameMention.count - 1, length: nameMention.count + 1)
                        let replacementText = ""
                        
                        let copyAttributedText = text.richText(isEditing: true, group_id: self.dataGroup["group_id"]  as? String ?? "", listMentionInTextField: listMentionInTextField)
                        copyAttributedText.removeAttribute(.foregroundColor, range: rangeReplacement)
                        
                        textView.attributedText = copyAttributedText

                        // Replace the old text with the new text using the replaceSubrange(_:with:) method
                        if let startIndex = text.index(text.startIndex, offsetBy: rangeReplacement.location, limitedBy: text.endIndex),
                           let endIndex = text.index(startIndex, offsetBy: rangeReplacement.length, limitedBy: text.endIndex) {
                            text.replaceSubrange(startIndex..<endIndex, with: replacementText)
                        }
                        listMentionInTextField.remove(at: i)
                        
                        textView.attributedText = text.richText(isEditing: true, group_id: self.dataGroup["group_id"]  as? String ?? "", listMentionInTextField: listMentionInTextField)
                        
                        let newPosition = textView.position(from: textView.beginningOfDocument, offset: textView.text.count - diff)
                        textView.selectedTextRange = textView.textRange(from: newPosition!, to: newPosition!)
                        textViewDidChangeSelection(textView)
                        handleRichText(textView)
                        return false
                    }
                }
            }
        }
        let indent = handleIndent(textView, range, text)
        if !indent {
            textViewDidChangeSelection(textView)
            handleRichText(textView)
            return indent
        }
        if (textView.text.count == 0) {
            return text != "\n"
        }
        return true
    }
    
    private func handleIndent(_ textView: UITextView, _ range: NSRange, _ text: String) -> Bool {
        guard let nsText = textView.text as NSString? else { return true }
        let newText = nsText.replacingCharacters(in: range, with: text)
        var lines = newText.components(separatedBy: "\n")
        
        // Ensure range location is valid, considering Unicode scalars
        guard let textRange = Range(range, in: textView.text) else { return true }
        let prefixText = textView.text[..<textRange.lowerBound]
        let affectedLineIndex = prefixText.components(separatedBy: "\n").count - 1
        guard affectedLineIndex >= 0, affectedLineIndex < lines.count else { return true }
        
        let affectedLine = lines[affectedLineIndex]
        // Auto-indent new lines based on previous line
        if text == "\n" {
            let previousLine = lines[affectedLineIndex]
            
            if previousLine.hasPrefix("  •") {
                let newBullet = "\n  • "
                textView.text = nsText.replacingCharacters(in: range, with: newBullet)
                DispatchQueue.main.async {
                    textView.selectedRange = NSRange(location: range.location + newBullet.utf16.count, length: 0)
                }
                return false
            }
            
            if let match = previousLine.range(of: #"^\s{2}(\d+)\."#, options: .regularExpression),
               let numberMatch = previousLine[match].components(separatedBy: ".").first,
               let number = Int(numberMatch.trimmingCharacters(in: .whitespaces)) {
                
                let newNumber = "\n  \(number + 1). "
                textView.text = nsText.replacingCharacters(in: range, with: newNumber)
                DispatchQueue.main.async {
                    textView.selectedRange = NSRange(location: range.location + newNumber.utf16.count, length: 0)
                }
                return false
            }
        }
        
        // Handle Backspace on Empty Bullet (Convert "  • " → "- ")
        if text.isEmpty && affectedLine.trimmingCharacters(in: .whitespaces) == "•" {
            lines[affectedLineIndex] = "- "  // Replace "  • " with "- "
            textView.text = lines.joined(separator: "\n")
            DispatchQueue.main.async {
                textView.selectedRange = NSRange(location: range.location - 1, length: 0)
            }
            return false
        }
        
        // Handle Backspace on bullet
        if text.isEmpty, newText.hasPrefix(" •"), newText.substring(with: NSRange(location: range.location - 1, length: 2)) == " •" {
            return false
        }
        
        // Handle Backspace on Numbered List
        if text.isEmpty, newText.hasPrefix("  "), newText.substring(with: NSRange(location: range.location - 2, length: 2)) == "  " {
            lines[affectedLineIndex] = affectedLine.trimmingCharacters(in: .whitespaces)
            textView.text = lines.joined(separator: "\n")
            DispatchQueue.main.async {
                textView.selectedRange = NSRange(location: range.location - 2, length: 0)
            }
            return false
        }
        return true
    }
    
    private func handleRichText(_ textView: UITextView) {
        textView.attributedText = textView.text.richText(isEditing: true, group_id: self.dataGroup["group_id"]  as? String ?? "", listMentionInTextField: self.listMentionInTextField)
    }
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL?, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        var urlString: String?

        if let url = URL {
            urlString = url.absoluteString
        } else {
            if let range = Range(characterRange, in: textView.text) {
                let tappedText = String(textView.text[range])
                urlString = tappedText
            }
        }
        
        guard let finalURL = urlString else {
            return false
        }

        switch interaction {
        case .invokeDefaultAction:
            let gesture = ObjectGesture()
            gesture.message_id = finalURL
            tapMessageText(gesture)
            return false

        case .presentActions:
            UIPasteboard.general.string = finalURL
            self.view.makeToast("Link Copied".localized(), duration: 3)
            return false

        case .preview:
            return true

        @unknown default:
            return true
        }
    }
}

extension EditorGroup: UIContextMenuInteractionDelegate {
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        if showMenuContext {
            showMenuContext = false
            interaction.view!.removeInteraction(interaction)
        }
    }
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        if textFieldSend.isFirstResponder {
            textFieldSend.resignFirstResponder()
        }
        let indexPath = self.tableChatView.indexPathForRow(at: interaction.view!.convert(location, to: self.tableChatView))
        let dataMessages = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == dataDates[indexPath!.section]})
        var star: UIAction
        if (dataMessages[indexPath!.row]["is_stared"]  as? String ?? "" == "0") {
            star = UIAction(title: "Star".localized(), image: UIImage(systemName: "star"), handler: {(_) in
                if self.removed {
                    return
                }
                DispatchQueue.global().async {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                "is_stared" : 1
                            ], _where: "message_id = '\(dataMessages[indexPath!.row]["message_id"]  as? String ?? "")'")
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                }
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == dataMessages[indexPath!.row]["message_id"]  as? String ?? ""})
                if idx != nil{
                    self.dataMessages[idx!]["is_stared"] = "1"
                }
                self.tableChatView.reloadRows(at: [indexPath!], with: .none)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "listenerStarMessage"), object: nil, userInfo: nil)
            })
        } else {
            star = UIAction(title: "Unstar".localized(), image: UIImage(systemName: "star.slash"), handler: {(_) in
                if self.removed {
                    return
                }
                DispatchQueue.global().async {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                "is_stared" : 0
                            ], _where: "message_id = '\(dataMessages[indexPath!.row]["message_id"]  as? String ?? "")'")
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                }
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == dataMessages[indexPath!.row]["message_id"]  as? String ?? ""})
                if idx != nil{
                    self.dataMessages[idx!]["is_stared"] = "0"
                }
                self.tableChatView.reloadRows(at: [indexPath!], with: .none)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "listenerStarMessage"), object: nil, userInfo: nil)
            })
        }
        
        let reply = UIAction(title: "Reply".localized(), image: UIImage(systemName: "arrowshape.turn.up.left"), handler: {(_) in
            if self.removed {
                return
            }
            if self.isSearching {
                self.cancelAction()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                self.handleReply(indexPath: indexPath!)
            })
        })
        var pin: UIAction
        if (dataMessages[indexPath!.row][TypeDataMessage.is_pinned] as? String ?? "0" == "0") {
            pin = UIAction(title: "Pin".localized(), image: UIImage(systemName: "pin"), handler: {(_) in
                if self.removed {
                    return
                }
                if self.isSearching {
                    self.cancelAction()
                }
                var checkDataPinned = self.dataMessages.filter({ $0[TypeDataMessage.is_pinned] as? String ?? "0" != "0"})
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                    if checkDataPinned.count == 3 {
                        let alert = UIAlertController(title: "Replace oldest pin?".localized(),
                                                      message: "Your pin will replace the oldest one.".localized(),
                                                      preferredStyle: .alert)

                        alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
                            proceedPinned(replace: true)
                        })

                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                        })
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        proceedPinned()
                    }
                })
                func proceedPinned(replace: Bool = false) {
                    if !CheckConnection.isConnectedToNetwork() || API.nGetCLXConnState() == 0 {
                        DispatchQueue.main.async {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        }
                        return
                    }
                    if replace {
                        checkDataPinned.sort {
                            let firstPinned = Int64($0[TypeDataMessage.is_pinned] as? String ?? "0") ?? 0
                            let secondPinned = Int64($1[TypeDataMessage.is_pinned] as? String ?? "0") ?? 0
                            return firstPinned < secondPinned
                        }
                        self.proceedPinUnpinMessage(checkDataPinned: checkDataPinned[0], isPinned: false) { res1 in
                            if res1 {
                                self.proceedPinUnpinMessage(checkDataPinned: dataMessages[indexPath!.row], isPinned: true) { res2 in
                                    if res2 {
                                        let dataMessagesPin = self.dataMessages.filter({ $0[TypeDataMessage.is_pinned] as? String ?? "0" != "0"})
                                        DispatchQueue.main.async {
                                            self.pinAllMessages(dataMessages: dataMessagesPin)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        self.proceedPinUnpinMessage(checkDataPinned: dataMessages[indexPath!.row], isPinned: true) { res in
                            if res {
                                let dataMessagesPin = self.dataMessages.filter({ $0[TypeDataMessage.is_pinned] as? String ?? "0" != "0"})
                                DispatchQueue.main.async {
                                    self.pinAllMessages(dataMessages: dataMessagesPin)
                                }
                            }
                        }
                    }
                }
            })
        } else {
            pin = UIAction(title: "Unpin".localized(), image: UIImage(systemName: "pin.slash"), handler: {(_) in
                if self.removed {
                    return
                }
                if self.isSearching {
                    self.cancelAction()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                    self.proceedPinUnpinMessage(checkDataPinned: dataMessages[indexPath!.row], isPinned: false) { res in
                        if res {
                            let dataMessagesPin = self.dataMessages.filter({ $0[TypeDataMessage.is_pinned] as? String ?? "0" != "0"})
                            DispatchQueue.main.async {
                                self.pinAllMessages(dataMessages: dataMessagesPin)
                            }
                        }
                    }
                })
            })
        }
        let replyP = UIAction(title: "Reply Privately".localized(), image: UIImage(systemName: "arrowshape.turn.up.left"), handler: {(_) in
            if self.removed {
                return
            }
            if self.isSearching {
                self.cancelAction()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                let f_pin = dataMessages[indexPath!.row]["f_pin"] as? String ?? ""
                let message_id = dataMessages[indexPath!.row][TypeDataMessage.message_id] as? String ?? ""
                if let dataSaved: String = SecureUserDefaults.shared.value(forKey: "new_saved_\(f_pin)") {
                    let data = dataSaved
                    if let jsonData = data.data(using: .utf8),
                       let dataJson = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] {
                        let last_m = dataJson["text"] ?? ""
                        let data: [String: String] = ["text": last_m, "reffId": message_id]
                        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
                           let jsonString = String(data: jsonData, encoding: .utf8) {
                            SecureUserDefaults.shared.set(jsonString, forKey: "new_saved_\(f_pin)")
                        }
                    }
                } else {
                    let data: [String: String] = ["text": "", "reffId": message_id]
                    if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        SecureUserDefaults.shared.set(jsonString, forKey: "new_saved_\(f_pin)")
                    }
                }
                let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                editorPersonalVC.hidesBottomBarWhenPushed = true
                editorPersonalVC.unique_l_pin = f_pin
                if let nav = self.navigationController {
                    nav.show(editorPersonalVC, sender: nil)
                    nav.viewControllers.remove(at: nav.viewControllers.count - 2)
                }
            })
        })
        let forward = UIAction(title: "Forward".localized(), image: UIImage(systemName: "arrowshape.turn.up.right"), handler: {(_) in
            if self.removed {
                return
            }
            if self.isSearching {
                self.cancelAction()
            }
            if self.reffId != nil {
                self.deleteReplyView()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.forwardSession = true
                let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
                if !self.isHistoryCC {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = true
                }
                self.addMultipleSelectSession()
                self.tableChatView.reloadData()
            }
        })
        let copy = UIAction(title: "Copy".localized(), image: UIImage(systemName: "doc.on.doc"), handler: {(_) in
            if self.removed {
                return
            }
            if self.isSearching {
                self.cancelAction()
            }
            if self.reffId != nil {
                self.deleteReplyView()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.copySession = true
                let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
                if !self.isHistoryCC {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = true
                }
                self.addMultipleSelectSession()
                self.tableChatView.reloadData()
            }
        })
        let edit = UIAction(title: "Edit".localized(), image: UIImage(systemName: "pencil.tip.crop.circle"), handler: {(_) in
            self.isEditingMessage = true
            self.showEditMessageView(at: indexPath!)
        })
        let translate = UIAction(title: "Translate".localized(), image: UIImage(systemName: "t.bubble"), handler: {(_) in
            self.view.makeToast("Translating...".localized(), duration: 3)
            var translation: String = "English"
            let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
            if lang == "id" {
                translation = "Indonesia"
            }
            let payload: [String : Any] = [
                "role": "user",
                "content": dataMessages[indexPath!.row][TypeDataMessage.message_text]!!
            ]
            let parameter: [String : Any] = [
                "use_video": "0",
                "translate": translation,
                "payload": [payload]
            ]
            DispatchQueue.global().async {
                Utils.postDataWithCookiesAndUserAgent(from: URL(string: Utils.getGPTBotUrl())!, parameter: parameter, completion: { data, response, error in
                    let response = response as? HTTPURLResponse
                    if response?.statusCode != 200 || error != nil {
                        DispatchQueue.main.async {
                            self.view.makeToast("There is an error occurred while translating your message. Please try again or check your network connection.".localized(), duration: 3)
                        }
                        return
                    }
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        if let json = try? JSONSerialization.jsonObject(with: responseString.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [String: String] {
                            let dataContent = json["content"]!
                            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
                            if idx != nil{
                                self.dataMessages[idx!][TypeDataMessage.message_text] = (dataMessages[indexPath!.row][TypeDataMessage.message_text] as? String ?? "") + "\n\n" + "$\(dataContent)$"
                            }
                            DispatchQueue.main.async{
                                self.tableChatView.reloadRows(at: [indexPath!], with: .none)
                            }
                        }
                    }
                })
            }
        })
        let gcs = UIAction(title: "Get Chat Suggestion".localized(), image: UIImage(systemName: "exclamationmark.bubble"), handler: {(_) in
            self.view.makeToast("Getting chat suggestion...".localized(), duration: 3)
            let payload: [String : Any] = [
                "role": "user",
                "content": dataMessages[indexPath!.row][TypeDataMessage.message_text]!!
            ]
            let parameter: [String : Any] = [
                "use_video": "0",
                "suggest": "1",
                "payload": [payload]
            ]
            DispatchQueue.global().async {
                Utils.postDataWithCookiesAndUserAgent(from: URL(string: Utils.getGPTBotUrl())!, parameter: parameter, completion: { data, response, error in
                    let response = response as? HTTPURLResponse
                    if response?.statusCode != 200 || error != nil {
                        DispatchQueue.main.async {
                            self.view.makeToast("There is an error occurred while getting chat suggestion for you. Please try again or check your network connection.".localized(), duration: 3)
                        }
                        return
                    }
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        if let json = try? JSONSerialization.jsonObject(with: responseString.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [String: Any] {
                            if let dataMessage = json["message"] as? [[String: Any]] {
                                if let dataContent = dataMessage[0]["content"] as? String {
                                    DispatchQueue.main.async{
                                        self.textFieldSend.text = dataContent
                                        self.textFieldSend.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black
                                    }
                                }
                            }
                            
                        }
                    }
                })
            }
        })
        let more = UIMenu(title: "More...".localized(), children: [translate, gcs])
        let info = UIAction(title: "Info".localized(), image: UIImage(systemName: "info.circle"), handler: {(_) in
            if self.removed {
                return
            }
            let messageInfoVC = MessageInfo()
            messageInfoVC.data = dataMessages[indexPath!.row]
            messageInfoVC.dataGroup = self.dataGroup
            messageInfoVC.isPersonal = false
            self.navigationController?.pushViewController(messageInfoVC, animated: true)
        })
        let delete = UIAction(title: "Delete".localized(), image: UIImage(systemName: "trash"), attributes: .destructive, handler: {(_) in
            if self.removed {
                return
            }
            if self.isSearching {
                self.cancelAction()
            }
            if self.reffId != nil {
                self.deleteReplyView()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.deleteSession = true
                let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
                if !self.isHistoryCC {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = true
                }
                self.addMultipleSelectSession()
                self.tableChatView.reloadData()
            }
        })
        
        let resend = UIAction(title: "Resend".localized(), image: UIImage(systemName: "arrow.clockwise"), handler: {(_) in
            let messageId = dataMessages[indexPath!.row][TypeDataMessage.message_id]  as? String ?? ""
            let status = dataMessages[indexPath!.row][TypeDataMessage.status]  as? String ?? ""
            
            var idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String ?? "" == messageId })
            if let idxMessageIdParent = self.groupImages.firstIndex(where: { $0.value.contains(where: { $0.messageId == messageId }) }) {
                if let idxInImages = self.groupImages[idxMessageIdParent].value.firstIndex(where: { $0.messageId == messageId }) {
                    self.groupImages[idxMessageIdParent].value[idxInImages].status = "1"
                    self.groupImages[idxMessageIdParent].value[idxInImages].dataMessage[TypeDataMessage.status] = "1"
                }
                idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.groupImages[idxMessageIdParent].key })
            }
            
            if (idx != nil) {
                do {
                    self.dataMessages[idx!][TypeDataMessage.status] = "1"
                    self.dataMessages[idx!][TypeDataMessage.progress] = 0.0
                    let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
                    let row = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataMessages[idx!]["chat_date"]  as? String ?? ""}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                    if row != nil && section != nil  {
                        self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                    }
                } catch {
                }
            }
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                        "status" : "1"
                    ], _where: "message_id = '\(messageId)'")
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                        "status" : "1"
                    ], _where: "message_id = '\(messageId)'")
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
            let message = CoreMessage_TMessageBank.sendMessage(message_id: messageId,
                                                               l_pin: dataMessages[indexPath!.row][TypeDataMessage.l_pin]  as? String ?? "",
                                                               message_scope_id: dataMessages[indexPath!.row][TypeDataMessage.message_scope_id]  as? String ?? "",
                                                               status: "1",
                                                               message_text: dataMessages[indexPath!.row][TypeDataMessage.message_text]  as? String ?? "",
                                                               credential: dataMessages[indexPath!.row][TypeDataMessage.credential]  as? String ?? "",
                                                               attachment_flag: dataMessages[indexPath!.row][TypeDataMessage.attachment_flag]  as? String ?? "",
                                                               ex_blog_id: dataMessages[indexPath!.row][TypeDataMessage.blog_id]  as? String ?? "",
                                                               message_large_text: "",
                                                               ex_format: "",
                                                               image_id: dataMessages[indexPath!.row][TypeDataMessage.image_id]  as? String ?? "",
                                                               audio_id: dataMessages[indexPath!.row][TypeDataMessage.audio_id]  as? String ?? "",
                                                               video_id: dataMessages[indexPath!.row][TypeDataMessage.video_id]  as? String ?? "",
                                                               file_id: dataMessages[indexPath!.row][TypeDataMessage.file_id]  as? String ?? "",
                                                               thumb_id: dataMessages[indexPath!.row][TypeDataMessage.thumb_id]  as? String ?? "",
                                                               reff_id: dataMessages[indexPath!.row][TypeDataMessage.reff_id]  as? String ?? "",
                                                               read_receipts: dataMessages[indexPath!.row][TypeDataMessage.read_receipts]  as? String ?? "",
                                                               chat_id: dataMessages[indexPath!.row][TypeDataMessage.chat_id]  as? String ?? "",
                                                               is_call_center: dataMessages[indexPath!.row][TypeDataMessage.is_call_center]  as? String ?? "",
                                                               call_center_id: dataMessages[indexPath!.row][TypeDataMessage.call_center_id]  as? String ?? "",
                                                               opposite_pin: dataMessages[indexPath!.row][TypeDataMessage.opposite_pin]  as? String ?? "", specFile: "")
            Nexilis.addQueueMessage(message: message)
        })
        
        var children: [UIMenuElement] = [star, reply, pin, copy, delete]
        var isMore = false
//        let copyOption = self.copyOption(indexPath: indexPath!)
        let idMe = User.getMyPin() as String?
        
        if dataMessages[indexPath!.row]["status"]  as? String ?? "" == "0" {
            children = [resend, delete]
        } else if (dataMessages[indexPath!.row]["lock"] != nil && dataMessages[indexPath!.row]["lock"]  as? String ?? "" == "1") || dataMessages[indexPath!.row]["message_scope_id"]  as? String ?? "" == "18" || dataMessages[indexPath!.row]["credential"]  as? String ?? "" == "1" {
            children = [delete]
        } else if (groupImages[dataMessages[indexPath!.row]["message_id"]  as? String ?? ""] != nil) {
            forward.title = "Forward All".localized()
            delete.title = "Delete All".localized()
            children = [delete]
            if (Nexilis.checkingAccess(key: "secure_folder_forward") || (dataMessages[indexPath!.row][TypeDataMessage.spec_file] as? String ?? "").contains("forward")) && dataMessages[indexPath!.row]["read_receipts"] as? String != "8" {
                children.insert(forward, at: 0)
            }
        } else {
            if dataMessages[indexPath!.row]["f_pin"] as? String ?? "" == "-999" {
                children = [star, reply ,delete]
            }
            else if !(dataMessages[indexPath!.row]["image_id"] as? String ?? "").isEmpty || !(dataMessages[indexPath!.row]["video_id"] as? String ?? "").isEmpty || !(dataMessages[indexPath!.row]["file_id"] as? String ?? "").isEmpty {
                children = [star, reply, pin, delete]
            } else if dataMessages[indexPath!.row]["attachment_flag"]  as? String ?? "" == "11" {
                children = [reply, pin, delete]
            }
            if (Nexilis.checkingAccess(key: "secure_folder_forward") || (!(dataMessages[indexPath!.row][TypeDataMessage.message_text]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["image_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["video_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["file_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["audio_id"]  as? String ?? "").isEmpty) || (dataMessages[indexPath!.row][TypeDataMessage.spec_file] as? String ?? "").contains("forward")) && dataMessages[indexPath!.row]["read_receipts"] as? String != "8" && dataMessages[indexPath!.row]["attachment_flag"] as? String ?? "" != "11" {
                children.insert(forward, at: 2)
            }
            if dataMessages[indexPath!.row]["f_pin"] as? String ?? "" != "-999" && dataMessages[indexPath!.row]["f_pin"] as? String != User.getMyPin() && dataMessages[indexPath!.row]["attachment_flag"]  as? String ?? "" != "11" {
                children.insert(replyP, at: 2)
            }
            if (dataMessages[indexPath!.row]["f_pin"]  as? String ?? "") == idMe {
                children.insert(info, at: children.count - 1)
            }
            if !(dataMessages[indexPath!.row][TypeDataMessage.message_text]  as? String ?? "").isEmpty {
                if (dataMessages[indexPath!.row]["f_pin"]  as? String ?? "") == idMe && ((dataMessages[indexPath!.row][TypeDataMessage.is_forwarded] as? Int) ?? 0) == 0 && (dataMessages[indexPath!.row][TypeDataMessage.attachment_flag] as? String ?? "") != "11" {
                    let valueDate = Date(milliseconds: Int64(dataMessages[indexPath!.row][TypeDataMessage.server_date] as? String ?? "") ?? 0)
                    let nowDate = Date()
                    let diffInSeconds = nowDate.timeIntervalSince(valueDate)
                    if diffInSeconds <= 15 * 60 {
                        children.insert(edit, at: children.count - 1)
                    }
                }
                if (dataMessages[indexPath!.row][TypeDataMessage.attachment_flag] as? String ?? "") != "11" && (dataMessages[indexPath!.row]["image_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["video_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["file_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["audio_id"]  as? String ?? "").isEmpty{
                    isMore = true
                }
            }
        }
        
        let mainMenu = UIMenu(title: "", options: [.displayInline],
                              children: children)
        var menuForShow = UIMenu(title: "", children: [mainMenu])
        if isMore {
            menuForShow = UIMenu(title: "", children: [mainMenu, more])
        }
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { _ in
            return menuForShow
        }
    }
    
    func proceedPinUnpinMessage(checkDataPinned: [String: Any?], isPinned: Bool, completion: @escaping (Bool)-> Void) {
        DispatchQueue.global().async {
            var jaData = [[String: Any]]()
            var jsonObject = [String: Any]()
            jsonObject[CoreMessage_TMessageKey.MESSAGE_ID] = checkDataPinned["message_id"]  as? String ?? ""
            jsonObject[CoreMessage_TMessageKey.IS_PINNED_MESSAGE] = isPinned ? "\(Date().currentTimeMillis())" : "0"
            jaData.append(jsonObject)
            if let jsonData = try? JSONSerialization.data(withJSONObject: jaData, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getPinMessage(f_pin: User.getMyPin() ?? "", data: jsonString, oppositePin: self.dataGroup["group_id"]  as? String ?? "", chatId: self.dataTopic["chat_id"] as? String ?? "", scopeId: MessageScope.GROUP)) {
                    if response.isOk() {
                        if isPinned {
                            let mId = Nexilis.saveMessageNotif(textMessage: "You".localized() + " " + "pinned a message".localized(), fPin: User.getMyPin() ?? "", lPin: self.unique_l_pin, chatId: self.dataTopic["chat_id"] as? String ?? "", scopeId: MessageScope.GROUP)
                            self.appendNewMessage(messageId: mId)
                        }
                        DispatchQueue.global().async {
                            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                do {
                                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                        "is_pinned" : isPinned ? "\(Date().currentTimeMillis())" : "0"
                                    ], _where: "message_id = '\(checkDataPinned["message_id"]  as? String ?? "")'")
                                } catch {
                                    rollback.pointee = true
                                    print("Access database error: \(error.localizedDescription)")
                                }
                            })
                        }
                        let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == checkDataPinned["message_id"]  as? String ?? ""})
                        if idx != nil{
                            self.dataMessages[idx!][TypeDataMessage.is_pinned] = isPinned ? "\(Date().currentTimeMillis())" : "0"
                            let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
                            let row = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataMessages[idx!]["chat_date"]  as? String ?? ""}).firstIndex(where: { $0["message_id"]  as? String ?? "" == self.dataMessages[idx!]["message_id"]  as? String ?? "" })
                            if row != nil && section != nil  {
                                DispatchQueue.main.async {
                                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                }
                            }
                        }
                        completion(true)
                    } else {
                        DispatchQueue.main.async {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Failed to pin or unpin message, make sure you are connected to internet".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        }
                        completion(false)
                    }
                } else {
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                    completion(false)
                }
            }
        }
    }
    
    private func appendNewMessage(messageId: String) {
        var row: [String: Any?] = [:]
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared, blog_id, credential, is_call_center, call_center_id, opposite_pin, last_edited, gif_id, is_forwarded_message, attachment_speciality, is_pinned from MESSAGE where message_id = '\(messageId)'"), cursorData.next() {
                row["message_id"] = cursorData.string(forColumnIndex: 0)
                row["f_pin"] = cursorData.string(forColumnIndex: 1)
                row["l_pin"] = cursorData.string(forColumnIndex: 2)
                row["message_scope_id"] = cursorData.string(forColumnIndex: 3)
                row["server_date"] = cursorData.string(forColumnIndex: 4)
                row["status"] = cursorData.string(forColumnIndex: 5)
                row["message_text"] = cursorData.string(forColumnIndex: 6)
                row["audio_id"] = cursorData.string(forColumnIndex: 7)
                row["video_id"] = cursorData.string(forColumnIndex: 8)
                row["image_id"] = cursorData.string(forColumnIndex: 9)
                row["thumb_id"] = cursorData.string(forColumnIndex: 10)
                row["read_receipts"] = cursorData.string(forColumnIndex: 11)
                row["chat_id"] = cursorData.string(forColumnIndex: 12)
                row["file_id"] = cursorData.string(forColumnIndex: 13)
                row["attachment_flag"] = cursorData.string(forColumnIndex: 14)
                row["reff_id"] = cursorData.string(forColumnIndex: 15)
                row["lock"] = cursorData.string(forColumnIndex: 16)
                row["is_stared"] = cursorData.string(forColumnIndex: 17)
                row["blog_id"] = cursorData.string(forColumnIndex: 18)
                row["credential"] = cursorData.string(forColumnIndex: 19)
                row[TypeDataMessage.is_call_center] = cursorData.string(forColumnIndex: 20)
                row[TypeDataMessage.call_center_id] = cursorData.string(forColumnIndex: 21)
                row[TypeDataMessage.opposite_pin] = cursorData.string(forColumnIndex: 22)
                row[TypeDataMessage.last_edit] = cursorData.longLongInt(forColumnIndex: 23)
                row[TypeDataMessage.gif_id] = cursorData.string(forColumnIndex: 24)
                row[TypeDataMessage.is_forwarded] = Int(cursorData.int(forColumnIndex: 25))
                row[TypeDataMessage.spec_file] = cursorData.string(forColumnIndex: 26)
                row[TypeDataMessage.is_pinned] = cursorData.string(forColumnIndex: 27)
                row["progress"] = 0.0
                row["isSelected"] = false
                row["chat_date"] = "Today".localized()
                cursorData.close()
            }
        })
        DispatchQueue.main.async {
            if !self.dataDates.contains("Today".localized()) {
                self.dataDates.append("Today".localized())
                self.tableChatView.insertSections(IndexSet(integer: self.dataDates.count - 1), with: .none)
            }
            self.tableChatView.beginUpdates()
            self.dataMessages.append(row)
            self.tableChatView.insertRows(at: [IndexPath(row: self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataDates[self.dataDates.count - 1]}).count - 1, section: self.dataDates.count - 1)], with: .none)
            self.tableChatView.endUpdates()
        }
    }
    
    func showEditMessageView(at indexPath: IndexPath) {
        tempListMentionWithText = listMentionWithText
        tempListMentionInTextField = listMentionInTextField
        listMentionWithText.removeAll()
        listMentionInTextField.removeAll()
        let dataMessages = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == dataDates[indexPath.section]})
        let oldText = dataMessages[indexPath.row][TypeDataMessage.message_text]  as? String ?? ""
        var oldTextForTextview = oldText
        let pattern = "@[\\w]+"
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsrange = NSRange(oldText.startIndex..., in: oldText)
            let matches = regex.matches(in: oldText, range: nsrange)
            
            let results = matches.map {
                String(oldText[Range($0.range, in: oldText)!])
            }
            for result in results {
                let pinRes = result.components(separatedBy: "@")[1]
                Database.shared.database?.inTransaction({ fmdb, rollback in
                    do {
                        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_pin, first_name || ' ' || ifnull(last_name, '') name FROM GROUPZ_MEMBER where f_pin = '\(pinRes)'"), cursor.next() {
                            let user = User(pin: "")
                            user.pin = cursor.string(forColumnIndex: 0) ?? ""
                            user.firstName = cursor.string(forColumnIndex: 1) ?? ""
                            if !user.pin.isEmpty {
                                var fixUser = User.getDataCanNil(pin: user.pin, fmdb: fmdb)
                                if fixUser == nil {
                                    fixUser = user
                                }
                                var indexAt = 0
                                if let range = oldTextForTextview.range(of: result) {
                                    indexAt = oldTextForTextview.distance(from: oldTextForTextview.startIndex, to: range.lowerBound)
                                }
                                fixUser?.ex_block = "\(indexAt + fixUser!.fullName.count)"
                                listMentionWithText.append(fixUser!)
                                listMentionInTextField.append(fixUser!)
                                oldTextForTextview = oldTextForTextview.replacingOccurrences(of: result, with: "@\(fixUser!.fullName)")
                                lastTextLength = oldTextForTextview.count
                            }
                            cursor.close()
                        } else if pinRes == "-997" {
                            let gptUser = User(pin: "-997",
                                            firstName: Utils.getGPTBotName(),
                                            lastName: "",
                                            thumb: "",
                                            userType: "0",
                                            official: "1")
                            var indexAt = 0
                            if let range = oldTextForTextview.range(of: result) {
                                indexAt = oldTextForTextview.distance(from: oldTextForTextview.startIndex, to: range.lowerBound)
                            }
                            gptUser.ex_block = "\(indexAt + gptUser.fullName.count)"
                            listMentionWithText.append(gptUser)
                            listMentionInTextField.append(gptUser)
                            oldTextForTextview = oldTextForTextview.replacingOccurrences(of: result, with: "@\(gptUser.fullName)")
                            lastTextLength = oldTextForTextview.count
                        }
                    } catch {
                        rollback.pointee = true
                        print("Access database error: \(error.localizedDescription)")
                    }
                })
            }
        } catch {
            print("Invalid regex pattern")
        }
        editVC = UIViewController()
        if let view = editVC.view {
//            let tapGesture = ObjectGesture(target: self, action: #selector(dismissEditVC))
//            tapGesture.message_id = oldTextForTextview
//            view.addGestureRecognizer(tapGesture)
            
            view.backgroundColor = .clear
            let blurView = UIView()
            let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = blurView.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blurView.addSubview(blurEffectView)
            blurView.sendSubviewToBack(blurEffectView)
            view.addSubview(blurView)
            blurView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor)
            
            let tapGesture = ObjectGesture(target: self, action: #selector(dismissEditVC))
            tapGesture.message_id = oldTextForTextview
            blurView.addGestureRecognizer(tapGesture)
            
            editTextView = CustomTextView()
            editTextView.layer.cornerRadius = textFieldSend.maxCornerRadius()
            editTextView.layer.borderWidth = 1.0
            editTextView.textColor = UIColor.black
            editTextView.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
            editTextView.textContainerInset = UIEdgeInsets(top: 12, left: 20, bottom: 11, right: 40)
            editTextView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
            editTextView.font = UIFont.systemFont(ofSize: 12 + offset())
            editTextView.delegate = self
            editTextView.allowsEditingTextAttributes = true
            editTextView.backgroundColor = .clear
            view.addSubview(editTextView)
            editTextView.anchor(left: view.leftAnchor, right: view.rightAnchor, paddingLeft: 15, paddingRight: 15)
            constraintBottomeditTextView = editTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15)
            constraintHeighteditTextView = editTextView.heightAnchor.constraint(equalToConstant: 40)
            constraintBottomeditTextView.isActive = true
            constraintHeighteditTextView.isActive = true
            editTextView.attributedText = oldTextForTextview.richText(isEditing: true, group_id: self.dataGroup["group_id"]  as? String ?? "", listMentionInTextField: listMentionInTextField)
            editTextView.becomeFirstResponder()
            
            buttonSendEdit.setImage(resizeImage(image: self.traitCollection.userInterfaceStyle == .dark ? UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(.blackDarkMode) : UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal), for: .normal)
            buttonSendEdit.circle()
            buttonSendEdit.isEnabled = true
            buttonSendEdit.actionHandle(controlEvents: .touchUpInside,
             ForAction:{() -> Void in
                var newText = self.editTextView.text ?? ""
                if newText.contains("@") && self.listMentionInTextField.count > 0 {
                    var diff: Int = 0
                    for i in 0..<self.listMentionInTextField.count {
                        let mention = self.listMentionInTextField[i]
                        guard let exBlockStr = mention.ex_block, let exBlock = Int(exBlockStr) else {
                            continue // skip if ex_block is nil or not an integer
                        }
                        let nameWithMention = ("@" + mention.firstName + " " + mention.lastName).trimmingCharacters(in: .whitespaces)
                        let pinString = "@\(mention.pin)"
                        let upperBound = exBlock + diff
                        let lowerBound = upperBound - nameWithMention.count + 1
                        guard lowerBound >= 0, upperBound < newText.count else {
                            continue // prevent index out-of-range
                        }
                        var afterMention = ""
                        let nextCharIndex = newText.index(newText.startIndex, offsetBy: upperBound + 1, limitedBy: newText.endIndex)
                        if let index = nextCharIndex, index < newText.endIndex {
                            let nextChar = newText[index]
                            if nextChar != "\n" && nextChar != " " {
                                afterMention = " "
                            }
                        }
                        let startIndex = newText.index(newText.startIndex, offsetBy: lowerBound)
                        let endIndex = newText.index(newText.startIndex, offsetBy: upperBound + 1)
                        let range = startIndex..<endIndex
                        if newText[range] == nameWithMention {
                            newText.replaceSubrange(range, with: pinString + afterMention)
                            diff += (pinString + afterMention).count - nameWithMention.count
                        }
                    }
                }
                if !newText.isEmpty && newText.trimmingCharacters(in: .whitespacesAndNewlines) != oldText {
                    let lastEdited = Int64(Date().currentTimeMillis())
                    let message = CoreMessage_TMessageBank.editMessage(message_id: dataMessages[indexPath.row][TypeDataMessage.message_id]  as? String ?? "", l_pin: dataMessages[indexPath.row][TypeDataMessage.l_pin]  as? String ?? "", message_scope_id: dataMessages[indexPath.row][TypeDataMessage.message_scope_id]  as? String ?? "", status: "1", message_text: newText, credential: dataMessages[indexPath.row][TypeDataMessage.credential]  as? String ?? "", attachment_flag: dataMessages[indexPath.row][TypeDataMessage.attachment_flag]  as? String ?? "", ex_blog_id: dataMessages[indexPath.row][TypeDataMessage.blog_id]  as? String ?? "", message_large_text: "", ex_format: "", image_id: dataMessages[indexPath.row][TypeDataMessage.image_id]  as? String ?? "", audio_id: dataMessages[indexPath.row][TypeDataMessage.audio_id]  as? String ?? "", video_id: dataMessages[indexPath.row][TypeDataMessage.video_id]  as? String ?? "", file_id: dataMessages[indexPath.row][TypeDataMessage.file_id]  as? String ?? "", thumb_id: dataMessages[indexPath.row][TypeDataMessage.thumb_id]  as? String ?? "", reff_id: dataMessages[indexPath.row][TypeDataMessage.reff_id]  as? String ?? "", read_receipts: dataMessages[indexPath.row][TypeDataMessage.read_receipts]  as? String ?? "", chat_id: dataMessages[indexPath.row][TypeDataMessage.chat_id]  as? String ?? "", is_call_center: dataMessages[indexPath.row][TypeDataMessage.is_call_center]  as? String ?? "", call_center_id: dataMessages[indexPath.row][TypeDataMessage.call_center_id]  as? String ?? "", opposite_pin: dataMessages[indexPath.row][TypeDataMessage.opposite_pin]  as? String ?? "", server_date: dataMessages[indexPath.row][TypeDataMessage.server_date]  as? String ?? "", local_time_stamp: dataMessages[indexPath.row][TypeDataMessage.server_date]  as? String ?? "", last_edit: lastEdited)
                    Nexilis.addQueueMessage(message: message, isEditMessage: true)
                    DispatchQueue.global().async {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                    "message_text" : newText,
                                    "last_edited" : lastEdited
                                ], _where: "message_id = '\(dataMessages[indexPath.row]["message_id"]  as? String ?? "")'")
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                    }
                    let idx = self.dataMessages.firstIndex(where: { $0[TypeDataMessage.message_id] as? String == dataMessages[indexPath.row][TypeDataMessage.message_id] as? String})
                    if idx != nil{
                        self.dataMessages[idx!][TypeDataMessage.message_text] = newText
                        self.dataMessages[idx!][TypeDataMessage.last_edit] = lastEdited
                        self.tableChatView.reloadRows(at: [indexPath], with: .none)
                    }
                }
                self.isEditingMessage = false
                self.listMentionWithText = self.tempListMentionWithText
                self.listMentionInTextField = self.tempListMentionWithText
                self.lastTextLength = self.textFieldSend.text?.count ?? 0
                self.heightTableEditMention = nil
                self.editVC.dismiss(animated: true)
             })
            buttonSendEdit.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
            view.addSubview(buttonSendEdit)
            buttonSendEdit.anchor(right: view.rightAnchor, paddingRight: 15, width: 40, height: 40)
            constraintBottomSendEditTV = buttonSendEdit.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15)
            constraintBottomSendEditTV.isActive = true
            
            let viewMessage = UIView()
            view.addSubview(viewMessage)
            viewMessage.translatesAutoresizingMaskIntoConstraints = false
            if (dataMessages[indexPath.row][TypeDataMessage.f_pin] as? String == User.getMyPin()) {
                viewMessage.leftAnchor.constraint(greaterThanOrEqualTo: view.leftAnchor, constant: 60).isActive = true
                viewMessage.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -15).isActive = true
                viewMessage.backgroundColor = .blueBubbleColor
                viewMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
            } else {
                viewMessage.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor, constant: 60).isActive = true
                viewMessage.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 15).isActive = true
                viewMessage.backgroundColor = .whiteBubbleColor
                viewMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            }
            viewMessage.bottomAnchor.constraint(equalTo: editTextView.topAnchor, constant: -15).isActive = true
            viewMessage.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            viewMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            viewMessage.layer.cornerRadius = 10.0
            viewMessage.clipsToBounds = true
            
            let messageText = UILabel()
            messageText.numberOfLines = 0
            messageText.lineBreakMode = .byWordWrapping
            viewMessage.addSubview(messageText)
            messageText.translatesAutoresizingMaskIntoConstraints = false
            messageText.topAnchor.constraint(equalTo: viewMessage.topAnchor, constant: 15).isActive = true
            messageText.leadingAnchor.constraint(equalTo: viewMessage.leadingAnchor, constant: 15).isActive = true
            messageText.bottomAnchor.constraint(equalTo: viewMessage.bottomAnchor, constant: -15).isActive = true
            messageText.trailingAnchor.constraint(equalTo: viewMessage.trailingAnchor, constant: -15).isActive = true
            messageText.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
            messageText.font = .systemFont(ofSize: 12 + offset())
            messageText.attributedText = oldText.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
            
            tableMentionEdit = UITableView()
            tableMentionEdit.register(UITableViewCell.self, forCellReuseIdentifier: "cellEditMention")
            tableMentionEdit.dataSource = self
            tableMentionEdit.delegate = self
            tableMentionEdit.contentInset = UIEdgeInsets(top: -25, left: 0, bottom: 0, right: 0)
            tableMentionEdit.backgroundColor = .white
            view.addSubview(tableMentionEdit)
            tableMentionEdit.anchor(left: view.leftAnchor, bottom: editTextView.topAnchor, right: view.rightAnchor)
            heightTableEditMention = tableMentionEdit.heightAnchor.constraint(equalToConstant: 0)
            self.heightTableEditMention.isActive = true
        }
        editVC.modalTransitionStyle = .crossDissolve
        editVC.modalPresentationStyle = .overFullScreen
        self.present(editVC, animated: true, completion: {
            self.constraintHeighteditTextView.constant = self.editTextView.contentSize.height
            if self.constraintHeighteditTextView.constant > 95 {
                self.constraintHeighteditTextView.constant = 95.0
            }
        })
    }
    
    @objc func dismissEditVC(_ sender: ObjectGesture) {
        if editTextView.text == sender.message_id {
            isEditingMessage = false
            listMentionWithText = tempListMentionWithText
            listMentionInTextField = tempListMentionWithText
            lastTextLength = textFieldSend.text?.count ?? 0
            heightTableEditMention = nil
            editVC.dismiss(animated: true)
        } else if self.isEditingMessage {
            let alert = LibAlertController(title: "".localized(), message: "Discard edit?".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: UIAlertAction.Style.cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Discard".localized(), style: UIAlertAction.Style.default, handler: {(_) in
                self.isEditingMessage = false
                self.listMentionWithText = self.tempListMentionWithText
                self.listMentionInTextField = self.tempListMentionWithText
                self.lastTextLength = self.textFieldSend.text?.count ?? 0
                self.heightTableEditMention = nil
                self.editVC.dismiss(animated: true)
            }))
            editVC.present(alert, animated: true, completion: nil)
        } else {
            lastTextLength = self.textFieldSend.text?.count ?? 0
            editVC.dismiss(animated: true)
        }
    }
    
    @objc func cancelAction() {
        DispatchQueue.main.async {
            if self.copySession {
                self.copySession = false
            } else if self.forwardSession {
                self.forwardSession = false
            } else if self.deleteSession {
                self.deleteSession = false
            } else if self.isSearching {
                self.countMatchesSearch = 0
                self.isSearching = false
            }
            if self.viewTextfield.isHidden {
                self.viewTextfield.isHidden = false
            }
            if self.viewAttachment.isHidden {
                self.viewAttachment.isHidden = false
            }
            if self.containerAction.isHidden {
                self.containerAction.isHidden = false
            }
            if self.viewButton.isHidden {
                self.viewButton.isHidden = false
            }
            if self.constraintBottomTableViewWithTextfield.constant == -60.0 {
                self.constraintBottomTableViewWithTextfield.constant = self.constraintBottomTableViewWithTextfield.constant + 70
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    if (self.currentIndexpath != nil) {
                        self.tableChatView.scrollToRow(at: IndexPath(row: self.currentIndexpath!.row, section: self.currentIndexpath!.section), at: .none, animated: true)
                    } else {
                        self.tableChatView.scrollToBottom()
                    }
                })
            }
            let data = self.dataMessages.filter({ $0["isSelected"] as! Bool == true })
            for i in 0..<data.count {
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == data[i]["message_id"]  as? String ?? ""})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = false
                }
            }
            self.tableChatView.reloadData()
            self.setRightButtonItem()
            self.changeAppBar()
            self.containerMultpileSelectSession.removeFromSuperview()
            self.checkNewMessage(tableView: self.tableChatView)
        }
    }
    
    private func addMultipleSelectSession() {
        viewTextfield.isHidden = true
        viewAttachment.isHidden = true
        containerAction.isHidden = true
        viewButton.isHidden = true
        constraintBottomTableViewWithTextfield.constant = constraintBottomTableViewWithTextfield.constant - 70
        view.addSubview(containerMultpileSelectSession)
        containerMultpileSelectSession.translatesAutoresizingMaskIntoConstraints = false
        constraintBottomContainerMultpileSelectSession = containerMultpileSelectSession.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0)
        NSLayoutConstraint.activate([
            containerMultpileSelectSession.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            containerMultpileSelectSession.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            constraintBottomContainerMultpileSelectSession,
            containerMultpileSelectSession.heightAnchor.constraint(equalToConstant: 50)
        ])
        containerMultpileSelectSession.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        addSubviewMultipleSession()
    }
    
    private func addSubviewMultipleSession() {
        let container = UIView()
        containerMultpileSelectSession.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: containerMultpileSelectSession.leadingAnchor),
            container.trailingAnchor.constraint(equalTo:containerMultpileSelectSession.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: containerMultpileSelectSession.bottomAnchor),
            container.heightAnchor.constraint(equalToConstant: 50)
        ])
        container.layer.shadowOpacity = 0.7
        container.layer.shadowOffset = CGSize(width: 3, height: 3)
        container.layer.shadowRadius = 3.0
        container.layer.shadowColor = UIColor.black.cgColor
        container.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .secondaryColor
        
        if !isSearching {
            let title = UILabel()
            container.addSubview(title)
            title.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                title.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                title.centerYAnchor.constraint(equalTo:container.centerYAnchor),
            ])
            let countSelected = dataMessages.filter({ $0["isSelected"] as! Bool == true }).count
            title.text = "\(countSelected) " + "Selected".localized()
            title.textColor = .mainColor
            title.font = UIFont.systemFont(ofSize: 15).bold
            
            let button = UIImageView()
            container.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 15),
                button.centerYAnchor.constraint(equalTo:container.centerYAnchor),
                button.widthAnchor.constraint(equalToConstant: 30),
                button.heightAnchor.constraint(equalToConstant: 30),
            ])
            if copySession {
                button.image = UIImage(systemName: "doc.on.doc")
                if countSelected == 0{
                    button.tintColor = .gray
                } else {
                    button.tintColor = .mainColor
                }
            } else if forwardSession {
                button.image = UIImage(systemName: "arrowshape.turn.up.right")
                if countSelected == 0{
                    button.tintColor = .gray
                } else {
                    button.tintColor = .mainColor
                }
            } else if deleteSession {
                button.image = UIImage(systemName: "trash")
                if countSelected == 0{
                    button.tintColor = .gray
                } else {
                    button.tintColor = .red
                }
            }
            let buttonGesture = UITapGestureRecognizer(target: self, action: #selector(sessionAction))
            button.isUserInteractionEnabled = true
            button.addGestureRecognizer(buttonGesture)
            
            let selectedMessage = dataMessages.filter({ $0["isSelected"] as! Bool == true })
            if selectedMessage.count > 0 {
                for i in 0..<selectedMessage.count {
                    if let isGroupingImages = groupImages[selectedMessage[i]["message_id"]  as? String ?? ""] {
                        title.text = "\(countSelected + (isGroupingImages.count - 1)) " + "Selected".localized()
                    }
                }
            }
        } else {
            buttonUp = UIButton()
            container.addSubview(buttonUp)
            buttonUp.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                buttonUp.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
                buttonUp.centerYAnchor.constraint(equalTo:container.centerYAnchor),
                buttonUp.widthAnchor.constraint(equalToConstant: 30),
                buttonUp.heightAnchor.constraint(equalToConstant: 30),
            ])
            buttonUp.addTarget(self, action: #selector(upSearchText), for: .touchUpInside)
            
            buttonDown = UIButton()
            container.addSubview(buttonDown)
            buttonDown.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                buttonDown.leadingAnchor.constraint(equalTo: buttonUp.trailingAnchor, constant: 15),
                buttonDown.centerYAnchor.constraint(equalTo:container.centerYAnchor),
                buttonDown.widthAnchor.constraint(equalToConstant: 30),
                buttonDown.heightAnchor.constraint(equalToConstant: 30),
            ])
            buttonDown.addTarget(self, action: #selector(downSearchText), for: .touchUpInside)
            
            buttonUp.setImage(UIImage(systemName: "chevron.up"), for: .normal)
            buttonUp.tintColor = .gray
            
            buttonDown.setImage(UIImage(systemName: "chevron.down"), for: .normal)
            buttonDown.tintColor = .gray
            
            titleSearchMatches = UILabel()
            container.addSubview(titleSearchMatches)
            titleSearchMatches.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                titleSearchMatches.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                titleSearchMatches.centerYAnchor.constraint(equalTo:container.centerYAnchor),
            ])
            titleSearchMatches.textColor = .mainColor
            titleSearchMatches.font = UIFont.systemFont(ofSize: 15.0).bold
            titleSearchMatches.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                self.searchBar.becomeFirstResponder()
            })
        }
    }
    
    @objc func upSearchText() {
        scrollToFirstSearchMessage(indexScroll: lastScrollIdxSearch + 1)
    }
    
    @objc func downSearchText() {
        scrollToFirstSearchMessage(indexScroll: lastScrollIdxSearch - 1)
    }
    
    @objc func sessionAction() {
        if copySession {
            let dataMessages = self.dataMessages.filter({ $0["isSelected"] as! Bool == true })
            let countSelected = dataMessages.count
            if countSelected == 0 {
                return
            }
            var nameTopic = "Lounge".localized()
            if !dataTopic.isEmpty {
                nameTopic = dataTopic["title"]  as? String ?? ""
            }
            var text = "*^\(dataGroup["f_name"]!!) (\(nameTopic))^*"
            for i in 0..<countSelected {
                let stringDate = (dataMessages[i]["server_date"]  as? String ?? "")
                let date = Date(milliseconds: Int64(stringDate)!)
                let formatterDate = DateFormatter()
                let formatterTime = DateFormatter()
                formatterDate.dateFormat = "dd/MM/yy"
                formatterDate.locale = NSLocale(localeIdentifier: "id") as Locale?
                formatterTime.dateFormat = "HH:mm"
                formatterTime.locale = NSLocale(localeIdentifier: "id") as Locale?
                let dataProfile = getDataProfile(f_pin: dataMessages[i]["f_pin"]  as? String ?? "", message_id: dataMessages[i]["message_id"]  as? String ?? "")
                let textCopied = (dataMessages[i]["message_text"]  as? String ?? "").richText(isEditing: true, group_id: self.dataGroup["group_id"]  as? String ?? "")
                text = text + "\n\n*[\(formatterDate.string(from: date as Date)) \(formatterTime.string(from: date as Date))] \(dataProfile["name"]!):*\n\(textCopied.string)"
            }
            text = text + "\n\n\nchat " + "Powered by Nexilis".localized()
            DispatchQueue.main.async {
                UIPasteboard.general.string = text
                self.view.makeToast("Text coppied to clipboard".localized(), duration: 3)
            }
            cancelAction()
        } else if forwardSession {
            var dataMessages = self.dataMessages.filter({ $0["isSelected"] as! Bool == true })
            let countSelected = dataMessages.count
            if countSelected == 0 {
                return
            }
            for i in 0..<countSelected {
                if let groupingImages = groupImages[dataMessages[i]["message_id"]  as? String ?? ""] {
                    var tempData = dataMessages
                    tempData.remove(at: 0)
                    var dataMessageInGrouping = (groupImages[dataMessages[i]["message_id"]  as? String ?? ""]!).map({ $0.dataMessage })
                    tempData.insert(contentsOf: dataMessageInGrouping, at: i)
                    dataMessages = tempData
                }
            }
            contactChatNav.modalPresentationStyle = .custom
            contactChatNav.navigationBar.tintColor = .white
            contactChatNav.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
            contactChatNav.navigationBar.isTranslucent = false
            let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
            contactChatNav.navigationBar.titleTextAttributes = textAttributes
            let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
            UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
            contactChatNav.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
            if let controller = contactChatNav.viewControllers.first as? ContactChatViewController {
                controller.isChooser = { [weak self] scope, pin in
                    if scope == MessageScope.WHISPER || scope == MessageScope.CALL || scope == MessageScope.MISSED_CALL {
                        let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                        editorPersonalVC.unique_l_pin = pin
                        editorPersonalVC.dataMessageForward = dataMessages
                        self?.navigationController?.replaceAllViewController(with: editorPersonalVC, animated: true)
                    } else {
                        let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                        editorGroupVC.unique_l_pin = pin
                        editorGroupVC.dataMessageForward = dataMessages
                        self?.navigationController?.replaceAllViewController(with: editorGroupVC, animated: true)
                    }
                }
            }
            self.present(contactChatNav, animated: true, completion: nil)
        } else if deleteSession {
            let dataMessages = self.dataMessages.filter({ $0["isSelected"] as! Bool == true })
            let countSelected = dataMessages.count
            if countSelected == 0 {
                return
            }
            let alertController = LibAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            if let action = self.actionDelete(for: "me", title: "Delete".localized() + " \(countSelected) " + "For Me".localized(), dataMessages: dataMessages) {
                alertController.addAction(action)
            }
            let idMe = User.getMyPin() as String?
            let dataFilterFpin = dataMessages.filter({ $0["f_pin"] as? String != idMe})
            let dataFilterLock = dataMessages.filter({ $0["lock"] as? String == "1"})
//            let statusDataRead = dataMessages.filter({ Int($0["status"]  as? String ?? "")! >= 4})
            let statusFailed = dataMessages.filter({ Int($0["status"]  as? String ?? "")! == 0})
            if dataFilterFpin.count == 0 && dataFilterLock.count == 0 && statusFailed.count == 0 {
                if let action = self.actionDelete(for: "everyone", title: "Delete".localized() + " \(countSelected) " + "For Everyone".localized(), dataMessages: dataMessages) {
                    alertController.addAction(action)
                }
            }
            alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
            self.present(alertController, animated: true)
        }
    }
    
    private func deleteMessage(l_pin: String, message_id: String, scope: String, type: String, chat: String) {
        let tmessage = CoreMessage_TMessageBank.deleteMessage(l_pin: l_pin, messageId: message_id, scope: scope, type: type, chat: chat)
        Nexilis.deleteQueueMessage(message: tmessage)
    }
    
    private func queryMessageReply(message_id: String) -> [String: Any?] {
        var dataQuery: [String: Any] = [:]
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "SELECT message_id, f_pin, message_text, attachment_flag, thumb_id, image_id, video_id, file_id FROM MESSAGE where message_id='\(message_id)'"), c.next() {
                dataQuery["message_id"] = c.string(forColumnIndex: 0)
                dataQuery["f_pin"] = c.string(forColumnIndex: 1)
                dataQuery["message_text"] = c.string(forColumnIndex: 2)
                dataQuery["attachment_flag"] = c.string(forColumnIndex: 3)
                dataQuery["thumb_id"] = c.string(forColumnIndex: 4)
                dataQuery["image_id"] = c.string(forColumnIndex: 5)
                dataQuery["video_id"] = c.string(forColumnIndex: 6)
                dataQuery["file_id"] = c.string(forColumnIndex: 7)
                c.close()
            }
        })
        return dataQuery
    }
    
    @objc func segmentedControlValueChanged(_ sender: segmentedControllerObject) {
        switch sender.selectedSegmentIndex {
        case 0:
            sender.navigation.viewControllers[0].children[1].view.isHidden = true
            break;
        case 1:
            sender.navigation.viewControllers[0].children[1].view.isHidden = false
            break;
        default:
            break;
        }
    }
    
    private func copyOption(indexPath: IndexPath) -> UIMenu {
        var ratingButtonTitles = ["Text".localized(), "Image".localized()]
        if (dataMessages[indexPath.row]["message_text"]  as? String ?? "").isEmpty {
            ratingButtonTitles = ["Image".localized()]
        }
        let dataMessages = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == dataDates[indexPath.section]})
        let copyActions = ratingButtonTitles
            .enumerated()
            .map { index, title in
                return UIAction(
                    title: title,
                    identifier: nil,
                    handler: {(_) in
                        if (dataMessages[indexPath.row]["message_text"]  as? String ?? "").isEmpty {
                            DispatchQueue.main.async {
                                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                                if let dirPath = paths.first {
                                    let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(dataMessages[indexPath.row]["image_id"]  as? String ?? "")
                                    if FileManager.default.fileExists(atPath: imageURL.path) {
                                        let image    = UIImage(contentsOfFile: imageURL.path)
                                        UIPasteboard.general.image = image
                                        self.view.makeToast("Image coppied to clipboard".localized(), duration: 3)
                                    }
                                    else if FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
                                        do {
                                            if var imageData = try FileEncryption.shared.readSecure(filename: imageURL.lastPathComponent) {
                                                let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: imageData)
                                                if dataDecrypt != nil {
                                                    imageData = dataDecrypt!
                                                }
                                                let image = UIImage(data: imageData)
                                                UIPasteboard.general.image = image
                                                self.view.makeToast("Image coppied to clipboard".localized(), duration: 3)
                                            }
                                        } catch {
                                            
                                        }
                                    }
                                }
                            }
                            return
                        }
                        if (index == 0) {
                            DispatchQueue.main.async {
                                UIPasteboard.general.string = dataMessages[indexPath.row]["message_text"] as? String
                                self.view.makeToast("Text coppied to clipboard".localized(), duration: 3)
                            }
                        } else {
                            DispatchQueue.main.async {
                                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                                if let dirPath = paths.first {
                                    let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(dataMessages[indexPath.row]["image_id"]  as? String ?? "")
                                    if FileManager.default.fileExists(atPath: imageURL.path) {
                                        let image    = UIImage(contentsOfFile: imageURL.path)
                                        UIPasteboard.general.image = image
                                        self.view.makeToast("Image coppied to clipboard".localized(), duration: 3)
                                    } else if FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
                                        do {
                                            if var imageData = try FileEncryption.shared.readSecure(filename: imageURL.lastPathComponent) {
                                                let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: imageData)
                                                if dataDecrypt != nil {
                                                    imageData = dataDecrypt!
                                                }
                                                let image = UIImage(data: imageData)
                                                UIPasteboard.general.image = image
                                                self.view.makeToast("Image coppied to clipboard".localized(), duration: 3)
                                            }
                                        } catch {
                                            
                                        }
                                    }
                                }
                            }
                        }
                        self.dismissKeyboard()
                        
                    })
            }
        return UIMenu(
            title: "Copy".localized(),
            image: UIImage(systemName: "doc.on.doc.fill"),
            children: copyActions)
    }
    
    private func actionDelete(for type: String, title: String, dataMessages: [[String: Any?]]) -> UIAlertAction? {
        return UIAlertAction(title: title, style: .destructive) { [unowned self] _ in
            for i in 0..<dataMessages.count {
                if (type == "me") {
                    if let groupingImages = groupImages[dataMessages[i]["message_id"]  as? String ?? ""] {
                        for i in 0..<groupingImages.count {
                            self.deleteMessage(l_pin: dataGroup["group_id"]  as? String ?? "", message_id: groupingImages[i].messageId, scope: MessageScope.GROUP, type: "1", chat: dataTopic["chat_id"]  as? String ?? "")
                            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == groupingImages[i].messageId })
                            if idx != nil {
                                self.dataMessages.remove(at: idx!)
                                if (idx == self.dataMessages.count - 1) {
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                                }
                                for i in 0..<dataDates.count {
                                    if self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == dataDates[i] }).count == 0 {
                                        dataDates.remove(at: i)
                                    }
                                }
                            }
                        }
                        self.groupImages.removeValue(forKey: groupingImages[0].messageId)
                    } else {
                        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        } else {
                            if let groupingImages = groupImages[dataMessages[i]["message_id"]  as? String ?? ""] {
                                for i in 0..<groupingImages.count {
                                    self.deleteMessage(l_pin: dataGroup["group_id"]  as? String ?? "", message_id: groupingImages[i].messageId, scope: MessageScope.GROUP, type: "2", chat: dataTopic["chat_id"]  as? String ?? "")
                                    let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == groupingImages[i].messageId})
                                    if idx != nil {
                                        self.dataMessages[idx!]["lock"] = "1"
                                        self.dataMessages[idx!]["attachment_flag"] = "0"
                                        self.dataMessages[idx!]["reff_id"] = ""
                                    }
                                }
                                if let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == groupingImages[0].messageId}) {
                                    var dataMessageInGrouping = (groupImages[dataMessages[i]["message_id"]  as? String ?? ""]!).map({ $0.dataMessage })
                                    dataMessageInGrouping.remove(at: 0)
                                    self.dataMessages.insert(contentsOf: dataMessageInGrouping, at: idx+1)
                                    self.groupImages.removeValue(forKey: groupingImages[0].messageId)
                                }
                            } else {
                                self.deleteMessage(l_pin: dataGroup["group_id"]  as? String ?? "", message_id: dataMessages[i]["message_id"]  as? String ?? "", scope: MessageScope.GROUP, type: "1", chat: dataTopic["chat_id"]  as? String ?? "")
                                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[i]["message_id"] as? String})
                                if idx != nil {
                                    self.dataMessages.remove(at: idx!)
                                    if (idx == self.dataMessages.count - 1) {
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                                    }
                                    for i in 0..<dataDates.count {
                                        if self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == dataDates[i] }).count == 0 {
                                            dataDates.remove(at: i)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    self.deleteMessage(l_pin: dataGroup["group_id"]  as? String ?? "", message_id: dataMessages[i]["message_id"]  as? String ?? "", scope: MessageScope.GROUP, type: "2", chat: dataTopic["chat_id"]  as? String ?? "")
                    let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == dataMessages[i]["message_id"]  as? String ?? ""})
                    if idx != nil {
                        self.dataMessages[idx!]["lock"] = "1"
                        self.dataMessages[idx!]["attachment_flag"] = "0"
                        self.dataMessages[idx!]["reff_id"] = ""
                    }
                }
                if self.listTimerCredential[dataMessages[i]["message_id"]  as? String ?? ""] != nil {
                    self.listTimerCredential.removeValue(forKey: dataMessages[i]["message_id"]  as? String ?? "")
                    self.timerCredential[dataMessages[i]["message_id"]  as? String ?? ""]?.invalidate()
                    self.timerCredential.removeValue(forKey: dataMessages[i]["message_id"]  as? String ?? "")
                }
            }
            let dataMessagesPin = self.dataMessages.filter({ $0[TypeDataMessage.is_pinned] as? String ?? "0" != "0"})
            self.pinAllMessages(dataMessages: dataMessagesPin)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
            cancelAction()
        }
    }
    
    @objc func deleteReplyView() {
        if self.containerPreviewReply.isDescendant(of: self.viewTextfield) {
            self.containerPreviewReply.subviews.forEach { $0.removeFromSuperview() }
            self.containerPreviewReply.removeConstraints(self.containerPreviewReply.constraints)
            self.containerPreviewReply.removeFromSuperview()
            
            self.reffId = nil
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                self.constraintTopTextField.constant = self.constraintTopTextField.constant - 50 - (self.offset()*3)
                if self.contraintBottomMention.constant > 0 {
                    self.contraintBottomMention.constant = self.contraintBottomMention.constant - 50
                }
            }, completion: nil)
        }
    }
    
    @objc func removeLinkPreviewUntilEmptyTextView() {
        isAlwaysHideLinkPreview = true
        deleteLinkPreview()
    }
    
    @objc func deleteLinkPreview() {
        if self.containerLink.isDescendant(of: self.viewTextfield) {
            self.containerLink.subviews.forEach { $0.removeFromSuperview() }
            self.containerLink.removeConstraints(self.containerLink.constraints)
            self.containerLink.removeFromSuperview()
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                self.constraintTopTextField.constant = self.constraintTopTextField.constant - 80
                if self.contraintBottomMention.constant > 0 {
                    self.contraintBottomMention.constant = self.contraintBottomMention.constant - 80
                }
            }, completion: nil)
            self.showingLink = ""
        }
        if self.reffId != nil {
            self.bottomAnchorPreviewReply.isActive = false
            self.bottomAnchorPreviewReply = self.containerPreviewReply.bottomAnchor.constraint(equalTo: self.textFieldSend.topAnchor)
            self.bottomAnchorPreviewReply.isActive = true
        }
    }
}

extension EditorGroup: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 76
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellSticker", for: indexPath)
        if (cell.contentView.subviews.count > 0) {
            cell.contentView.subviews[0].removeFromSuperview()
        }
        let imageSticker = UIImageView()
        cell.contentView.addSubview(imageSticker)
        imageSticker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageSticker.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            imageSticker.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
            imageSticker.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            imageSticker.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
        ])
        var imageStickerBundle = UIImage(named: stickers[indexPath.row], in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
        if imageStickerBundle == nil {
            imageStickerBundle = UIImage(named: stickers[indexPath.row], in: Bundle.resourcesMediaBundle(for: Nexilis.self), with: nil)
        }
        imageSticker.image = imageStickerBundle //resourcesMediaBundle
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        sendChat(message_text: "sticker/\(stickers[indexPath.row])", attachment_flag: "11", viewController: self)
        constraintBottomAttachment.constant = 0.0
        self.viewSticker.removeConstraints(self.viewSticker.constraints)
        self.viewSticker.removeFromSuperview()
    }
    
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.previewItem!
    }
}

extension EditorGroup: UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate {
    //    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    //        checkNewMessage(tableView: tableView)
    //    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
            if self.tableChatView.alpha != 1.0 {
                UIView.animate(withDuration: 0.5, animations: {
                    self.tableChatView.alpha = 1.0
                })
            }
        })
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        lastY = scrollView.contentOffset.y
        DispatchQueue.main.async { [self] in
            if tableChatView.alpha != 1 {
                return
            }
            checkNewMessage(tableView: self.tableChatView)
        }
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == tableMention || tableView == tableMentionEdit || tableView == tableViewConfigFile {
            return 1
        }
        return dataDates.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == tableViewConfigFile {
            return 2
        }
        if tableView == tableMention || tableView == tableMentionEdit {
            return listMentionWithText.count
        }
        let count = dataMessages.filter({ $0["chat_date"]  as? String ?? "" == dataDates[section] }).count
        return count
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == tableViewConfigFile {
            return nil
        }
        if tableView == tableMention || tableView == tableMentionEdit {
            return .none
        }
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let dateView = UIView()
        containerView.addSubview(dateView)
        dateView.translatesAutoresizingMaskIntoConstraints = false
        var topAnchor = dateView.topAnchor.constraint(equalTo: containerView.topAnchor)
        topAnchor = dateView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10)
        NSLayoutConstraint.activate([
            topAnchor,
            dateView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            dateView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            dateView.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        dateView.backgroundColor = .orangeColor
        dateView.layer.cornerRadius = 8.0
        dateView.clipsToBounds = true
        
        let labelDate = UILabel()
        dateView.addSubview(labelDate)
        labelDate.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelDate.centerYAnchor.constraint(equalTo: dateView.centerYAnchor),
            labelDate.centerXAnchor.constraint(equalTo: dateView.centerXAnchor),
            labelDate.leadingAnchor.constraint(equalTo: dateView.leadingAnchor, constant: 10),
            labelDate.trailingAnchor.constraint(equalTo: dateView.trailingAnchor, constant: -10),
        ])
        labelDate.textAlignment = .center
        labelDate.textColor = .secondaryColor
        labelDate.font = UIFont.systemFont(ofSize: 12 + offset(), weight: .medium)
        labelDate.text = dataDates[section]
        return containerView
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == tableMention || tableView == tableMentionEdit || tableView == tableViewConfigFile {
            return 0
        }
        return 30
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == tableViewConfigFile {
            tableView.deselectRow(at: indexPath, animated: true)
            var type = ""
            if indexPath.row == 0 {
                type = "share,download"
            } else {
                type = "forward"
            }
            if !specFileString.contains(type) {
                if !specFileString.isEmpty {
                    specFileString += ","
                }
                specFileString += type
            } else {
                specFileString = specFileString.replacingOccurrences(of: type, with: "")
                if specFileString == "," {
                    specFileString = ""
                }
            }
            if specFileString.isEmpty {
                buttonSpec.setImage(UIImage(named: "pb_ic_attach_spc_off", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal).resize(target: CGSize(width: 30, height: 30)), for: .normal)
            } else {
                buttonSpec.setImage(UIImage(named: "pb_ic_attach_spc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal).resize(target: CGSize(width: 30, height: 30)), for: .normal)
            }
            tableView.reloadData()
            return
        }
        if tableView == tableMention || tableView == tableMentionEdit {
            tableView.deselectRow(at: indexPath, animated: true)
            var nowTextField = textFieldSend!
            if tableView == tableMentionEdit {
                nowTextField = editTextView
            }
            let fulltextForMention = nowTextField.text.substring(from: 0, to: lastPositionCursorMention - 1)
            let diff = nowTextField.text.count - fulltextForMention.count
            let lines = fulltextForMention.split(separator: "\n")
            if let lastLineIndex = lines.lastIndex(where: { !$0.isEmpty }) {
                let words = lines[lastLineIndex].split(separator: " ")
                if let lastWordIndex = words.lastIndex(where: { !$0.isEmpty }) {
                    var lastWord = words[lastWordIndex]
                    if let textM = extractFromAtIfSymbolsBefore(String(lastWord)) {
                        lastWord = textM[textM.startIndex..<textM.endIndex]
                    }
                    if let rangeLastWord = fulltextForMention.range(of: lastWord, options: .backwards) {
                        listMentionInTextField.append(listMentionWithText[indexPath.row])
                        
                        var addSpaceAfterReplacement = ""
                        if diff == 0 {
                            addSpaceAfterReplacement = " "
                        }
                        
                        var text = nowTextField.text ?? ""
                        let nameMention = listMentionWithText[indexPath.row].fullName.trimmingCharacters(in: .whitespaces)
                        listMentionInTextField.last?.ex_block = "\(fulltextForMention.distance(from: fulltextForMention.startIndex, to: rangeLastWord.lowerBound) + nameMention.count)" //upperbound
                        let replacementText = "@\(nameMention)"
                        
                        // Replace the old text with the new text using the replaceSubrange(_:with:) method
                        text.replaceSubrange(rangeLastWord, with: replacementText + addSpaceAfterReplacement)
                        
                        nowTextField.attributedText = text.richText(isEditing: true, group_id: self.dataGroup["group_id"]  as? String ?? "", listMentionInTextField: listMentionInTextField)
                        
                        let newPosition = nowTextField.position(from: nowTextField.beginningOfDocument, offset: nowTextField.text.count - diff)
                        nowTextField.selectedTextRange = nowTextField.textRange(from: newPosition!, to: newPosition!)
                        
                        hideMention()
                        lastTextLength = nowTextField.text.count
                        return
                    }
                }
            }
        }
        let dataMessages = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == dataDates[indexPath.section] })
        if copySession || forwardSession || deleteSession {
            guard indexPath.row < dataMessages.count else {
                return
            }
//            if copySession && dataMessages[indexPath.row]["f_pin"]  as? String ?? "" != "-999" {
//                return
//            }
            if (dataMessages[indexPath.row]["attachment_flag"]  as? String ?? "" != "0" || dataMessages[indexPath.row]["lock"] as? String == "1") && !forwardSession && !deleteSession {
                return
            }
            let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == dataMessages[indexPath.row]["message_id"]  as? String ?? ""})
            if idx != nil {
                self.dataMessages[idx!]["isSelected"] = !(self.dataMessages[idx!]["isSelected"] as! Bool)
                self.tableChatView.reloadRows(at: [indexPath], with: .none)
            }
            containerMultpileSelectSession.subviews.forEach({ $0.removeFromSuperview() })
            addSubviewMultipleSession()
            return
        }
        if !(dataMessages[indexPath.row]["image_id"]  as? String ?? "").isEmpty || !(dataMessages[indexPath.row]["video_id"]  as? String ?? "").isEmpty || !(dataMessages[indexPath.row]["file_id"]  as? String ?? "").isEmpty || !(dataMessages[indexPath.row]["audio_id"]  as? String ?? "").isEmpty {
            if !Nexilis.checkingAccess(key: "secure_folder_forward") && !(dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String ?? "").contains("forward") {
                return
            } else {
                var file = dataMessages[indexPath.row]["image_id"]  as? String ?? ""
                if file.isEmpty {
                    file = dataMessages[indexPath.row]["video_id"]  as? String ?? ""
                    if file.isEmpty {
                        file = dataMessages[indexPath.row]["file_id"]  as? String ?? ""
                        if file.isEmpty {
                            file = dataMessages[indexPath.row]["audio_id"]  as? String ?? ""
                        }
                    }
                }
                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                if let dirPath = paths.first {
                    let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(file)
                    if !FileManager.default.fileExists(atPath: fileURL.path) && !FileEncryption.shared.isSecureExists(filename: fileURL.lastPathComponent) {
                        return
                    }
                }
            }
        }
        let message = dataMessages[indexPath.row]
        if let attachmentFlag = message["attachment_flag"], let attachmentFlag = attachmentFlag as? String {
            if attachmentFlag == "27" || attachmentFlag == "26" {
                let streamingController = (attachmentFlag == "27") ? QmeraCreateStreamingViewController() : CreateSeminarViewController()
                switch(attachmentFlag){
                case "27":
                    (streamingController as! QmeraCreateStreamingViewController).isJoin = true
                default:
                    (streamingController as! CreateSeminarViewController).isJoin = true
                }
                if let messageText = message["message_text"],
                   let messageText = messageText as? String,
                   var json = try! JSONSerialization.jsonObject(with: messageText.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                    if json["blog"] == nil {
                        json["blog"] = message["blog_id"] ?? nil
                    }
                    switch(attachmentFlag){
                    case "27":
                        (streamingController as! QmeraCreateStreamingViewController).data = json
                    default:
                        (streamingController as! CreateSeminarViewController).data = json
                    }
                }
                let streamingNav = CustomNavigationController(rootViewController: streamingController)
                streamingNav.modalPresentationStyle = .custom
                streamingNav.navigationBar.tintColor = .white
                streamingNav.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
                streamingNav.navigationBar.isTranslucent = false
                streamingNav.navigationBar.overrideUserInterfaceStyle = .dark
                streamingNav.navigationBar.barStyle = .black
                let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
                UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
                let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                streamingNav.navigationBar.titleTextAttributes = textAttributes
                streamingNav.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
                streamingNav.navigationBar.isTranslucent = false
                navigationController?.present(streamingNav, animated: true, completion: nil)
            }
        }
    }
    
    
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == tableViewConfigFile {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellConfigFile", for: indexPath as IndexPath)
            var content = cell.defaultContentConfiguration()
            content.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
            content.textProperties.color = .label
            content.secondaryTextProperties.font = .systemFont(ofSize: 14)
            content.secondaryTextProperties.color = .gray
            if indexPath.row == 0 {
                content.text = "Can Share and Download".localized()
                content.secondaryText = "The user, as the receiver, can share and download the attachment.".localized()
                cell.accessoryType = specFileString.contains("share,download") ? .checkmark : .none
            } else {
                content.text = "Can Forward".localized()
                content.secondaryText = "The user, as the receiver, can forward the attachment.".localized()
                cell.accessoryType = specFileString.contains("forward") ? .checkmark : .none
            }
            cell.contentConfiguration = content
            cell.tintColor = .black
            return cell
        }
        if tableView == tableMention || tableView == tableMentionEdit {
            let cellMention = tableView.dequeueReusableCell(withIdentifier: tableView == tableMention ? "cellMention" : "cellEditMention", for: indexPath as IndexPath)
            var content = cellMention.defaultContentConfiguration()
            content.textProperties.font = UIFont.systemFont(ofSize: 11 + offset())
            content.imageProperties.tintColor = .black
            content.imageProperties.maximumSize = CGSize(width: 24, height: 24)
            if indexPath.row < listMentionWithText.count {
                if listMentionWithText[indexPath.row].pin == "-997" {
                    if let urlGif = Bundle.resourceBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif"), let data = try? Data(contentsOf: urlGif), let source = CGImageSourceCreateWithData(data as CFData, nil), let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                        let staticImage = UIImage(cgImage: cgImage)
                        content.image = staticImage.circleMasked
                    } else if let urlGif = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif"), let data = try? Data(contentsOf: urlGif), let source = CGImageSourceCreateWithData(data as CFData, nil), let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                        let staticImage = UIImage(cgImage: cgImage)
                        content.image = staticImage.circleMasked
                    }
                } else {
                    getImage(name: listMentionWithText[indexPath.row].thumb, placeholderImage: UIImage(systemName: "person"), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                        content.image = image
                    })
                }
                content.text = listMentionWithText[indexPath.row].firstName + " " + listMentionWithText[indexPath.row].lastName
            }
            cellMention.contentConfiguration = content
            return cellMention
        }
        let idMe = User.getMyPin() as String?
        let dataMessages = dataMessages.filter({$0["chat_date"]  as? String ?? "" == dataDates[indexPath.section]})
        
        let cellMessage = tableView.dequeueReusableCell(withIdentifier: "cellEditorGroup", for: indexPath as IndexPath)
        cellMessage.backgroundColor = .clear
        cellMessage.selectionStyle = .none
        cellMessage.contentView.subviews.forEach({ $0.removeConstraints($0.constraints) })
        cellMessage.contentView.subviews.forEach({ $0.removeFromSuperview() })
        
        let profileMessage = UIImageView()
        profileMessage.frame.size = CGSize(width: 35, height: 35)
        cellMessage.contentView.addSubview(profileMessage)
        profileMessage.translatesAutoresizingMaskIntoConstraints = false
        let tapGestureRecognizer = ObjectGesture(target: self, action: #selector(profilePersonTapped(_:)))
        tapGestureRecognizer.message_id = dataMessages[indexPath.row]["f_pin"]  as? String ?? ""
        profileMessage.isUserInteractionEnabled = true
        profileMessage.addGestureRecognizer(tapGestureRecognizer)
        
        let containerMessage = UIView()
        
        let messageIdChat = (dataMessages[indexPath.row]["message_id"] as? String) ?? ""
        let thumbChat = dataMessages[indexPath.row]["thumb_id"]  as? String ?? ""
        let imageChat = dataMessages[indexPath.row]["image_id"]  as? String ?? ""
        let videoChat = dataMessages[indexPath.row]["video_id"]  as? String ?? ""
        let fileChat = dataMessages[indexPath.row]["file_id"]  as? String ?? ""
        let reffChat = dataMessages[indexPath.row]["reff_id"]  as? String ?? ""
        let audioChat = (dataMessages[indexPath.row]["audio_id"] as? String) ?? ""
        let gifChat = (dataMessages[indexPath.row]["gif_id"] as? String) ?? ""
        let dataTimer = listTimerCredential[(dataMessages[indexPath.row]["message_id"]  as? String ?? "")]
        
        cellMessage.contentView.addSubview(containerMessage)
        containerMessage.translatesAutoresizingMaskIntoConstraints = false
        
        if messageIdChat.contains("NTFPIN_") {
            containerMessage.backgroundColor = .orangeColor
            containerMessage.anchor(top: cellMessage.contentView.topAnchor, bottom: cellMessage.contentView.bottomAnchor, paddingTop: 5, paddingBottom: 5, centerX: cellMessage.contentView.centerXAnchor, minWidth: 40, maxWidth: UIScreen.main.bounds.width - 40)
            containerMessage.layer.cornerRadius = 8
            containerMessage.clipsToBounds = true
            
            let textMessage = UILabel()
            containerMessage.addSubview(textMessage)
            textMessage.textAlignment = .center
            textMessage.anchor(top: containerMessage.topAnchor, left: containerMessage.leftAnchor, bottom: containerMessage.bottomAnchor, right: containerMessage.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10)
            textMessage.font = .systemFont(ofSize: 14)
            textMessage.text = dataMessages[indexPath.row][TypeDataMessage.message_text]  as? String ?? ""
            textMessage.textColor = .white
            return cellMessage
        }
        
        let timeMessage = UILabel()
        timeMessage.numberOfLines = 0
        cellMessage.contentView.addSubview(timeMessage)
        timeMessage.translatesAutoresizingMaskIntoConstraints = false
        if ((dataMessages[indexPath.row]["read_receipts"] as? String) == "8" ||
            (dataMessages[indexPath.row]["credential"] as? String) == "1" ||
            !(dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String ?? "").isEmpty) &&
            (dataMessages[indexPath.row]["lock"] as? String) != "2" &&
            (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            timeMessage.bottomAnchor.constraint(equalTo: cellMessage.contentView.bottomAnchor, constant: -40).isActive = true
        } else {
            timeMessage.bottomAnchor.constraint(equalTo: cellMessage.contentView.bottomAnchor, constant: -5).isActive = true
        }
        
        let messageText = UITextView()
        messageText.isEditable = false
        messageText.isSelectable = true
        messageText.dataDetectorTypes = [.link]
        messageText.backgroundColor = .clear
        messageText.isScrollEnabled = false
        messageText.textContainerInset = UIEdgeInsets.zero
        messageText.contentInset = UIEdgeInsets.zero
        messageText.textDragInteraction?.isEnabled = false
        containerMessage.addSubview(messageText)
        messageText.translatesAutoresizingMaskIntoConstraints = false
        var topMarginText = messageText.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 32)
        
        let dataProfile = getDataProfile(f_pin: dataMessages[indexPath.row]["f_pin"]  as? String ?? "", message_id: dataMessages[indexPath.row]["message_id"]  as? String ?? "")
        
        let statusMessage = UIImageView()
        
        if (dataMessages[indexPath.row]["attachment_flag"] as? String == "0" && dataMessages[indexPath.row]["lock"] as? String != "1") || forwardSession || deleteSession {
            var showSelectedImage = true
            if (!imageChat.isEmpty || !videoChat.isEmpty || !fileChat.isEmpty) && forwardSession {
                if !Nexilis.checkingAccess(key: "secure_folder_forward") && !(dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String ?? "").contains("forward") {
                    showSelectedImage = false
                } else {
                    var file = dataMessages[indexPath.row]["image_id"]  as? String ?? ""
                    if file.isEmpty {
                        file = dataMessages[indexPath.row]["video_id"]  as? String ?? ""
                        if file.isEmpty {
                            file = dataMessages[indexPath.row]["file_id"]  as? String ?? ""
                            if file.isEmpty {
                                file = dataMessages[indexPath.row]["audio_id"]  as? String ?? ""
                            }
                        }
                    }
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if let dirPath = paths.first {
                        let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(file)
                        if !FileManager.default.fileExists(atPath: fileURL.path) && !FileEncryption.shared.isSecureExists(filename: fileURL.lastPathComponent) {
                            showSelectedImage = false
                        }
                    }
                }
            }
            if dataMessages[indexPath.row]["f_pin"]  as? String ?? "" == "-999" && !deleteSession {
                showSelectedImage = false
            }
            if showSelectedImage {
                let selectedImage = UIImageView()
                cellMessage.contentView.addSubview(selectedImage)
                selectedImage.translatesAutoresizingMaskIntoConstraints = false
                selectedImage.frame.size = CGSize(width: 20, height: 20)
                var leading = selectedImage.leadingAnchor.constraint(equalTo: cellMessage.contentView.leadingAnchor, constant: -20)
                selectedImage.isHidden = true
                if copySession || forwardSession || deleteSession {
                    leading = selectedImage.leadingAnchor.constraint(equalTo: cellMessage.contentView.leadingAnchor, constant: 15)
                    selectedImage.isHidden = false
                }
                NSLayoutConstraint.activate([
                    leading,
                    selectedImage.centerYAnchor.constraint(equalTo: cellMessage.contentView.centerYAnchor),
                    selectedImage.widthAnchor.constraint(equalToConstant: 20),
                    selectedImage.heightAnchor.constraint(equalToConstant: 20)
                ])
                selectedImage.circle()
                selectedImage.layer.borderWidth = 2
                selectedImage.layer.borderColor = UIColor.mainColor.cgColor
                if dataMessages[indexPath.row]["isSelected"] as! Bool {
                    selectedImage.image = UIImage(systemName: "checkmark.circle.fill")
                }
                selectedImage.tintColor = .mainColor
            }
        }
        
        if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
            profileMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 5).isActive = true
            profileMessage.trailingAnchor.constraint(equalTo: cellMessage.contentView.trailingAnchor, constant: -15).isActive = true
            profileMessage.heightAnchor.constraint(equalToConstant: 37).isActive = true
            profileMessage.widthAnchor.constraint(equalToConstant: 35).isActive = true
            profileMessage.circle()
            profileMessage.clipsToBounds = true
            profileMessage.backgroundColor = .lightGray
            profileMessage.image = UIImage(systemName: "person")
            profileMessage.tintColor = .white
            profileMessage.contentMode = .scaleAspectFit
            
            let pictureImage = dataProfile["image_id"]
            if (pictureImage != "" && pictureImage != nil) {
                profileMessage.setImage(name: pictureImage!)
                profileMessage.contentMode = .scaleAspectFill
            }
            
            containerMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 5).isActive = true
            containerMessage.leadingAnchor.constraint(greaterThanOrEqualTo: cellMessage.contentView.leadingAnchor, constant: 60).isActive = true
            containerMessage.trailingAnchor.constraint(equalTo: profileMessage.leadingAnchor, constant: -5).isActive = true
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            containerMessage.layer.cornerRadius = 10.0
            containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
            containerMessage.clipsToBounds = true
            
            timeMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            
            if (dataMessages[indexPath.row]["lock"] as? String == "0" || (dataMessages[indexPath.row]["lock"] as? String ?? "").isEmpty) {
                cellMessage.contentView.addSubview(statusMessage)
                statusMessage.translatesAutoresizingMaskIntoConstraints = false
                statusMessage.bottomAnchor.constraint(equalTo: timeMessage.topAnchor).isActive = true
                statusMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
                statusMessage.widthAnchor.constraint(equalToConstant: 15).isActive = true
                statusMessage.heightAnchor.constraint(equalToConstant: 15).isActive = true
                var status = getRealStatus(messageId: dataMessages[indexPath.row]["message_id"]  as? String ?? "")
                if status == "-1" {
                    status = dataMessages[indexPath.row]["status"]! as? String ?? ""
                }
                if status == "0" {
                    statusMessage.image = UIImage(systemName: "xmark.circle")!.withTintColor(UIColor.red, renderingMode: .alwaysOriginal)
                } else if status == "1" {
                    statusMessage.image = UIImage(systemName: "clock.arrow.circlepath")!.withTintColor(UIColor.lightGray, renderingMode: .alwaysOriginal)
                } else if status == "2" {
                    statusMessage.image = UIImage(named: "checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
                } else if (status == "3") {
                    statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
                } else if (status == "8") {
                    statusMessage.image = UIImage(named: "message_status_ack", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
                } else {
                    statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
                }
            }
            
            let nameSender = UILabel()
            containerMessage.addSubview(nameSender)
            nameSender.translatesAutoresizingMaskIntoConstraints = false
            nameSender.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
            nameSender.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            nameSender.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
            nameSender.font = UIFont.systemFont(ofSize: 12 + offset()).bold
            nameSender.text = dataProfile["name"]
            nameSender.textAlignment = .right
            if (dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"]as? String == "") {
                containerMessage.backgroundColor = .clear
                nameSender.textColor = UIApplication.shared.visibleViewController?.traitCollection.userInterfaceStyle == .dark ? .lightGray : .mainColor
            } else {
                containerMessage.backgroundColor = .blueBubbleColor
                nameSender.textColor = UIApplication.shared.visibleViewController?.traitCollection.userInterfaceStyle == .dark ? .lightGray : .mainColor
            }
            
        } else {
            if copySession || forwardSession || deleteSession {
                profileMessage.leadingAnchor.constraint(equalTo: cellMessage.contentView.leadingAnchor, constant: 50).isActive = true
            } else {
                profileMessage.leadingAnchor.constraint(equalTo: cellMessage.contentView.leadingAnchor, constant: 15).isActive = true
            }
            profileMessage.heightAnchor.constraint(equalToConstant: 37).isActive = true
            profileMessage.widthAnchor.constraint(equalToConstant: 35).isActive = true
            profileMessage.circle()
            profileMessage.clipsToBounds = true
            profileMessage.backgroundColor = .lightGray
            profileMessage.image = UIImage(systemName: "person")
            profileMessage.tintColor = .white
            profileMessage.contentMode = .scaleAspectFit
            
            let pictureImage = dataProfile["image_id"]
            if dataMessages[indexPath.row]["f_pin"] as? String == "-999" {
                if !Utils.getIconDock().isEmpty {
                    let dataImage = try? Data(contentsOf: URL(string: Utils.getUrlDock()!)!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                    if dataImage != nil {
                        profileMessage.image = UIImage(data: dataImage!)
                    }
                } else {
                    profileMessage.image = UIImage(named: "pb_button", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                }
                profileMessage.contentMode = .scaleAspectFill
            }
            else if dataMessages[indexPath.row]["f_pin"] as? String == "-997" {
                if let urlGif = Bundle.resourceBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif") {
                    profileMessage.sd_setImage(with: urlGif) { (image, error, cacheType, imageURL) in
                        if error == nil {
                            profileMessage.animationImages = image?.images
                            profileMessage.animationDuration = image?.duration ?? 0.0
                            profileMessage.animationRepeatCount = 0
                            profileMessage.startAnimating()
                        }
                    }
                } else if let urlGif = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif") {
                    profileMessage.sd_setImage(with: urlGif) { (image, error, cacheType, imageURL) in
                        if error == nil {
                            profileMessage.animationImages = image?.images
                            profileMessage.animationDuration = image?.duration ?? 0.0
                            profileMessage.animationRepeatCount = 0
                            profileMessage.startAnimating()
                        }
                    }
                }
            }
            else if (pictureImage != "" && pictureImage != nil) {
                profileMessage.setImage(name: pictureImage!)
                profileMessage.contentMode = .scaleAspectFill
            }
            
            if markerCounter != nil && dataMessages[indexPath.row]["message_id"] as? String == markerCounter {
                profileMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 35).isActive = true
                containerMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 35).isActive = true
                
                let newMessagesView = UIView()
                cellMessage.contentView.addSubview(newMessagesView)
                newMessagesView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    newMessagesView.topAnchor.constraint(equalTo: newMessagesView.topAnchor),
                    newMessagesView.bottomAnchor.constraint(equalTo: containerMessage.topAnchor),
                    newMessagesView.centerXAnchor.constraint(equalTo: cellMessage.contentView.centerXAnchor),
                    newMessagesView.heightAnchor.constraint(equalToConstant: 30),
                    newMessagesView.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
                ])
                newMessagesView.backgroundColor = .greenColor
                newMessagesView.layer.cornerRadius = 15.0
                newMessagesView.clipsToBounds = true
                
                let labelNewMessages = UILabel()
                newMessagesView.addSubview(labelNewMessages)
                labelNewMessages.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    labelNewMessages.centerYAnchor.constraint(equalTo: newMessagesView.centerYAnchor),
                    labelNewMessages.centerXAnchor.constraint(equalTo: newMessagesView.centerXAnchor),
                    labelNewMessages.leadingAnchor.constraint(equalTo: newMessagesView.leadingAnchor, constant: 10),
                    labelNewMessages.trailingAnchor.constraint(equalTo: newMessagesView.trailingAnchor, constant: -10),
                ])
                labelNewMessages.textAlignment = .center
                labelNewMessages.textColor = .secondaryColor
                labelNewMessages.font = UIFont.systemFont(ofSize: 12 + offset(), weight: .medium)
                labelNewMessages.text = "Unread Messages".localized()
                
            } else {
                profileMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 5).isActive = true
                containerMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 5).isActive = true
            }
            
            containerMessage.leadingAnchor.constraint(equalTo: profileMessage.trailingAnchor, constant: 5).isActive = true
            containerMessage.trailingAnchor.constraint(lessThanOrEqualTo: cellMessage.contentView.trailingAnchor, constant: -60).isActive = true
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            if dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"]as? String == "" && dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1" && dataMessages[indexPath.row]["lock"] as? String != "2" {
                containerMessage.backgroundColor = .clear
            } else {
                containerMessage.backgroundColor = .whiteBubbleColor
            }
            containerMessage.layer.cornerRadius = 10.0
            containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            containerMessage.clipsToBounds = true
            
            timeMessage.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: 8).isActive = true
            
            let nameSender = UILabel()
            containerMessage.addSubview(nameSender)
            nameSender.translatesAutoresizingMaskIntoConstraints = false
            nameSender.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
            nameSender.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            nameSender.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
            nameSender.font = UIFont.systemFont(ofSize: 12 + offset()).bold
            if dataMessages[indexPath.row]["f_pin"] as? String == "-999" {
                nameSender.text = "Bot"
            }
            else if dataMessages[indexPath.row]["f_pin"] as? String == "-997" {
                nameSender.text = Utils.getGPTBotName()
            }
            else {
                nameSender.text = dataProfile["name"]
            }
            nameSender.textAlignment = .left
            nameSender.textColor = .mainColor
        }
        
        if ((dataMessages[indexPath.row]["read_receipts"] as? String) == "8" ||
            (dataMessages[indexPath.row]["credential"] as? String) == "1" ||
            !(dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String ?? "").isEmpty) &&
            (dataMessages[indexPath.row]["lock"] as? String) != "2" &&
            (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            containerMessage.bottomAnchor.constraint(equalTo: cellMessage.contentView.bottomAnchor, constant: -40).isActive = true
        } else {
            containerMessage.bottomAnchor.constraint(equalTo: cellMessage.contentView.bottomAnchor, constant: -5).isActive = true
        }
        
        let imageStared = UIImageView()
        let imageAckView = UIImageView()
        let imageCredentialView = UIImageView()
        let imagePinView = UIImageView()
        if dataMessages[indexPath.row]["is_stared"] as? String == "1" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" == "0") {
            cellMessage.contentView.addSubview(imageStared)
            imageStared.translatesAutoresizingMaskIntoConstraints = false
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                imageStared.bottomAnchor.constraint(equalTo: statusMessage.topAnchor).isActive = true
                imageStared.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            } else {
                imageStared.bottomAnchor.constraint(equalTo: timeMessage.topAnchor).isActive = true
                imageStared.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: 8).isActive = true
            }
            imageStared.widthAnchor.constraint(equalToConstant: 15).isActive = true
            imageStared.heightAnchor.constraint(equalToConstant: 15).isActive = true
            imageStared.image = UIImage(systemName: "star.fill")
            imageStared.backgroundColor = .clear
            imageStared.tintColor = .systemYellow
        }
        
        if dataMessages[indexPath.row][TypeDataMessage.is_pinned] as? String != nil && dataMessages[indexPath.row][TypeDataMessage.is_pinned] as? String != "0" {
            cellMessage.contentView.addSubview(imagePinView)
            imagePinView.translatesAutoresizingMaskIntoConstraints = false
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                if imageStared.isDescendant(of: cellMessage.contentView){
                    imagePinView.bottomAnchor.constraint(equalTo: imageStared.topAnchor).isActive = true
                } else {
                    imagePinView.bottomAnchor.constraint(equalTo: statusMessage.topAnchor).isActive = true
                }
                imagePinView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            } else {
                if imageStared.isDescendant(of: cellMessage.contentView){
                    imagePinView.bottomAnchor.constraint(equalTo: imageStared.topAnchor).isActive = true
                } else {
                    imagePinView.bottomAnchor.constraint(equalTo: timeMessage.topAnchor).isActive = true
                }
                imagePinView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: 8).isActive = true
            }
            imagePinView.widthAnchor.constraint(equalToConstant: 15).isActive = true
            imagePinView.heightAnchor.constraint(equalToConstant: 15).isActive = true
            imagePinView.image = UIImage(systemName: "pin.fill")
            imagePinView.backgroundColor = .clear
            imagePinView.tintColor = .lightGray
        }
        
        if dataMessages[indexPath.row]["read_receipts"] as? String == "8" && (dataMessages[indexPath.row]["lock"] as? String) != "2" && (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            var imageAck = UIImage(named: "ack_icon_gray", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            cellMessage.contentView.addSubview(imageAckView)
            imageAckView.translatesAutoresizingMaskIntoConstraints = false
            imageAckView.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageAckView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                let status = getRealStatus(messageId: dataMessages[indexPath.row]["message_id"]  as? String ?? "")
                if status == "8" {
                    imageAck = UIImage(named: "ack_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
                }
                imageAckView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
                imageAckView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 30).isActive = true
            } else {
                let status = dataMessages[indexPath.row]["status"] as? String
                if status == "8" {
                    imageAck = UIImage(named: "ack_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
                }
                imageAckView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
                imageAckView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -30).isActive = true
                let tap = ObjectGesture(target: self, action: #selector(tapAck(_:)))
                tap.indexPath = indexPath
                imageAckView.addGestureRecognizer(tap)
                imageAckView.isUserInteractionEnabled = true
            }
            imageAckView.image = imageAck
        }
        
        if (dataMessages[indexPath.row]["credential"] as? String) == "1" && (dataMessages[indexPath.row]["lock"] as? String) != "2" && (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            let imageCredential = UIImage(named: "confidential_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            imageCredentialView.image = imageCredential
            cellMessage.contentView.addSubview(imageCredentialView)
            imageCredentialView.translatesAutoresizingMaskIntoConstraints = false
            imageCredentialView.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageCredentialView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                imageCredentialView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
                imageCredentialView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 30).isActive = true
            } else {
                imageCredentialView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
                imageCredentialView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -30).isActive = true
            }
        }
        
        if !(dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String ?? "").isEmpty && (dataMessages[indexPath.row]["lock"] as? String) != "2" && (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            let imageSpecFileView = UIImageView()
            let imageSpecFile = UIImage(named: "pb_ic_attach_spc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            imageSpecFileView.image = imageSpecFile
            cellMessage.contentView.addSubview(imageSpecFileView)
            imageSpecFileView.translatesAutoresizingMaskIntoConstraints = false
            imageSpecFileView.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageSpecFileView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            imageSpecFileView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                if imageAckView.isDescendant(of: cellMessage.contentView) {
                    imageSpecFileView.leadingAnchor.constraint(equalTo: imageAckView.trailingAnchor, constant: 5).isActive = true
                } else if imageCredentialView.isDescendant(of: cellMessage.contentView) {
                    imageSpecFileView.leadingAnchor.constraint(equalTo: imageCredentialView.trailingAnchor, constant: 5).isActive = true
                } else {
                    imageSpecFileView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 30).isActive = true
                }
            } else {
                if imageAckView.isDescendant(of: cellMessage.contentView) {
                    imageSpecFileView.trailingAnchor.constraint(equalTo: imageAckView.leadingAnchor, constant: -5).isActive = true
                } else if imageCredentialView.isDescendant(of: cellMessage.contentView) {
                    imageSpecFileView.trailingAnchor.constraint(equalTo: imageCredentialView.leadingAnchor, constant: -5).isActive = true
                } else {
                    imageSpecFileView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -30).isActive = true
                }
            }
        }
        
        if dataMessages[indexPath.row]["attachment_flag"]  as? String ?? "" == "27" || dataMessages[indexPath.row]["attachment_flag"]  as? String ?? "" == "26" {
            messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 85).isActive = true
            let imageLS = UIImageView()
            containerMessage.addSubview(imageLS)
            imageLS.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageLS.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15.0),
                imageLS.trailingAnchor.constraint(equalTo: messageText.leadingAnchor, constant: -10.0),
                imageLS.centerYAnchor.constraint(equalTo: containerMessage.centerYAnchor),
                imageLS.heightAnchor.constraint(equalToConstant: 60.0)
            ])
            if dataMessages[indexPath.row]["attachment_flag"]  as? String ?? "" == "26" {
                imageLS.image = UIImage(named: "pb_seminar_wpr", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
            } else if dataMessages[indexPath.row]["attachment_flag"]  as? String ?? "" == "27" {
                imageLS.image = UIImage(named: "pb_live_tv", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
            }
        } else if !audioChat.isEmpty {
            messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 60).isActive = true
        } else {
            messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
        }
        messageText.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: -15).isActive = true
        messageText.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
        
        messageText.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        messageText.font = .systemFont(ofSize: 12 + offset())
        
        var textChat = dataMessages[indexPath.row]["message_text"] as? String ?? ""
        let originalMessageText = textChat
        if (dataMessages[indexPath.row]["lock"] != nil && (dataMessages[indexPath.row]["lock"])! as? String == "1") {
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                textChat = "🚫 _"+"You were deleted this message".localized()+"_"
            } else {
                textChat = "🚫 _"+"This message was deleted".localized()+"_"
            }
        }
        
        if dataMessages[indexPath.row]["lock"] as? String == "2" {
            textChat = "🚫 _"+"Message has expired".localized()+"_"
        }
        
        if !audioChat.isEmpty {
            textChat = textChat.components(separatedBy: "|")[0]
        }
        
        let imageSticker = UIImageView()
        
        if let attachmentFlag = dataMessages[indexPath.row]["attachment_flag"], let attachmentFlag = attachmentFlag as? String {
            if attachmentFlag == "27" || attachmentFlag == "26" { // live streaming
                if let json = try! JSONSerialization.jsonObject(with: textChat.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                    Database.shared.database?.inTransaction({ fmdb, rollback in
                        let title = json["title"]  as? String ?? ""
                        let description = json["description"]  as? String ?? ""
                        let start = json["time"] as! Int64
                        let by = json["by"]  as? String ?? ""
                        let textLS = "Live Streaming".localized()
                        var type = "*\(textLS)*"
                        if attachmentFlag == "26" {
                            let textSeminar = "Seminar".localized()
                            type = "*\(textSeminar)*"
                        }
                        if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || last_name from BUDDY where f_pin = '\(by)'"), c.next() {
                            let name = c.string(forColumnIndex: 0)!
                            messageText.attributedText = "\(type) \nTitle: \(title) \nDescription: \(description) \nStart: \(Date(milliseconds: start).format(dateFormat: "dd/MM/yyyy HH:mm")) \nBroadcaster: \(name)".richText()
                            c.close()
                        } else {
                            messageText.attributedText = ("\(type) \nTitle: \(title) \nDescription: \(description) \nStart: \(Date(milliseconds: start).format(dateFormat: "dd/MM/yyyy HH:mm")) \nBroadcaster: " + "Unknown".localized()).richText()
                        }
                    })
                }
            }
            else if attachmentFlag == "11" && dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1" && dataMessages[indexPath.row]["lock"] as? String != "2" {
                messageText.text = ""
                topMarginText.constant = topMarginText.constant + 100
                containerMessage.addSubview(imageSticker)
                imageSticker.translatesAutoresizingMaskIntoConstraints = false
                let data = queryMessageReply(message_id: reffChat)
                if reffChat.isEmpty || data.count == 0 {
                    imageSticker.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 32).isActive = true
                    imageSticker.widthAnchor.constraint(equalToConstant: 80).isActive = true
                } else {
                    imageSticker.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
                }
                imageSticker.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                imageSticker.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                imageSticker.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                var imageStickerBundle = UIImage(named: (textChat.components(separatedBy: "/")[1]), in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                if imageStickerBundle == nil {
                    imageStickerBundle = UIImage(named: (textChat.components(separatedBy: "/")[1]), in: Bundle.resourcesMediaBundle(for: Nexilis.self), with: nil)
                }
                imageSticker.image = imageStickerBundle //resourcesMediaBundle
                imageSticker.contentMode = .scaleAspectFit
            }
            else {
                messageText.attributedText = textChat.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
                modifyText()
            }
        } else {
            messageText.attributedText = textChat.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
            modifyText()
        }
        
        func modifyText() {
            if !textChat.isEmpty {
                if textChat.contains("■"){
                    textChat = textChat.components(separatedBy: "■")[0]
                    textChat = textChat.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                if !fileChat.isEmpty && dataMessages[indexPath.row]["lock"] as? String != "1" && dataMessages[indexPath.row]["lock"] as? String != "2" {
                    textChat = textChat.components(separatedBy: "|")[1]
                }
                let finalAtribute = textChat.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
                textChat = finalAtribute.string
                let urlPattern = "(https?://|www\\.)\\S+"
                if let regex = try? NSRegularExpression(pattern: urlPattern, options: []) {
                    let matches = regex.matches(in: textChat, options: [], range: NSRange(textChat.startIndex..., in: textChat))
                    
                    for match in matches {
                        if let range = Range(match.range, in: textChat) {
                            let linkText = String(textChat[range])
                            let nsRange = NSRange(range, in: textChat)
                            finalAtribute.addAttribute(.link, value: linkText, range: nsRange)
                            finalAtribute.addAttribute(.foregroundColor, value: UIColor.blue, range: nsRange)
                            finalAtribute.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
                        }
                    }
                }
                messageText.attributedText = finalAtribute
                messageText.delegate = self
            }
        }
        
        if !copySession && !forwardSession && !deleteSession && !isHistoryCC && !removed {
            let interaction = UIContextMenuInteraction(delegate: self)
            containerMessage.addInteraction(interaction)
            containerMessage.isUserInteractionEnabled = true
        }
        
        if isSearching && textSearch.count > 1 {
            messageText.attributedText = textChat.richText(isSearching: true, textSearch: textSearch, group_id: self.dataGroup["group_id"]  as? String ?? "")
        }
        
        let stringDate = (dataMessages[indexPath.row]["server_date"]  as? String ?? "")
        if !stringDate.isEmpty {
            if (dataMessages[indexPath.row]["credential"] as? String) == "1" && dataMessages[indexPath.row]["lock"] as? String != "2"  && dataMessages[indexPath.row]["lock"] as? String != "1" {
                if dataTimer! >= 10 {
                    timeMessage.text = "00:\(dataTimer!)"
                } else {
                    timeMessage.text = "00:0\(dataTimer!)"
                }
                timeMessage.textColor = .systemRed
            } else {
                let date = Date(milliseconds: Int64(stringDate) ?? 100)
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                timeMessage.text = formatter.string(from: date as Date)
                timeMessage.textColor = .lightGray
            }
            timeMessage.font = UIFont.systemFont(ofSize: 10 + offset(), weight: .medium)
            if dataMessages[indexPath.row][TypeDataMessage.last_edit] != nil && dataMessages[indexPath.row][TypeDataMessage.last_edit] as! Int64 != 0 {
                timeMessage.text = (timeMessage.text ?? "") + "\n" + "Edited".localized()
                if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                    timeMessage.textAlignment = .right
                }
            }
        }
        
        let imageThumb = UIImageView()
        let containerViewFile = UIView()
        let imageGif = SDAnimatedImageView()
        
        if !audioChat.isEmpty {
            messageText.isHidden = true
            let imageAudio = UIImageView()
            imageAudio.image = UIImage(systemName: "music.note", withConfiguration: UIImage.SymbolConfiguration(pointSize: 35))
            containerMessage.addSubview(imageAudio)
            imageAudio.anchor(top: containerMessage.topAnchor, left: containerMessage.leftAnchor, bottom: containerMessage.bottomAnchor, paddingTop: 15, paddingLeft: 15, paddingBottom: 15, centerY: containerMessage.centerYAnchor)
            imageAudio.tintColor = .mainColor
            
            let playButtonAudio = UIButton(type: .system)
            playButtonAudio.setImage(UIImage(systemName: "play.fill"), for: .normal)
            playButtonAudio.tintColor = .gray
            containerMessage.addSubview(playButtonAudio)
            playButtonAudio.anchor(left: containerMessage.leftAnchor, paddingLeft: 60, centerY: containerMessage.centerYAnchor, width: 20, height: 20)
            
            let progressSliderAudio = UISlider()
            progressSliderAudio.minimumValue = 0
            progressSliderAudio.maximumValue = 1
            let thumbImage = UIImage(systemName: "circle.fill")?.withTintColor(UIColor.mainColor)
                .resize(target: CGSize(width: 15, height: 15))
            progressSliderAudio.setThumbImage(thumbImage, for: .normal)
            containerMessage.addSubview(progressSliderAudio)
            progressSliderAudio.anchor(left: playButtonAudio.rightAnchor, right: containerMessage.rightAnchor, paddingLeft: 10, paddingRight: 15, centerY: containerMessage.centerYAnchor, height: 15)
            
            let timeLabelAudio = UILabel()
            timeLabelAudio.text = "0:00"
            timeLabelAudio.font = .systemFont(ofSize: 10 + offset())
            timeLabelAudio.textColor = .gray
            containerMessage.addSubview(timeLabelAudio)
            timeLabelAudio.anchor(top: playButtonAudio.bottomAnchor, left: playButtonAudio.rightAnchor, paddingLeft: 10, width: 100, height: 12)
            
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let audioURL = URL(fileURLWithPath: dirPath).appendingPathComponent(audioChat)
                var url = audioURL
                if !FileManager.default.fileExists(atPath: audioURL.path) && !FileEncryption.shared.isSecureExists(filename: audioChat) {
                    let activityIndicator = UIActivityIndicatorView(style: .medium)
                    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
                    activityIndicator.startAnimating()
                    playButtonAudio.setImage(nil, for: .normal)
                    playButtonAudio.addSubview(activityIndicator)
                    NSLayoutConstraint.activate([
                        activityIndicator.centerXAnchor.constraint(equalTo: playButtonAudio.centerXAnchor),
                        activityIndicator.centerYAnchor.constraint(equalTo: playButtonAudio.centerYAnchor)
                    ])
                    Download().startHTTP(forKey: audioChat) { (name, progress) in
                        guard progress == 100 else {
                            return
                        }
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }
                } else {
                    if !FileManager.default.fileExists(atPath: audioURL.path) {
                        do {
                            if var audioData = try FileEncryption.shared.readSecure(filename: audioChat) {
                                let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: audioData)
                                if dataDecrypt != nil {
                                    audioData = dataDecrypt!
                                }
                                let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                                let tempPath = cachesDirectory.appendingPathComponent(audioChat)
                                try audioData.write(to: tempPath)
                                url = tempPath
                            }
                        } catch {
                            
                        }
                    }
                    if audioPlayers[indexPath] == nil {
                        do {
                            let audioPlayer = try AVAudioPlayer(contentsOf: url)
                            audioPlayers[indexPath] = audioPlayer
                            audioPlayer.delegate = self
                            progressSliderAudio.maximumValue = Float(audioPlayer.duration)
                            timeLabelAudio.text = formatTime(audioPlayer.duration)
                        } catch {
                            print("Error loading audio: \(error)")
                        }
                    }
                    let audioPlayer = audioPlayers[indexPath]
                    if playingIndexPath == indexPath, let player = audioPlayer, player.isPlaying {
                        playButtonAudio.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                    } else {
                        playButtonAudio.setImage(UIImage(systemName: "play.fill"), for: .normal)
                    }

                    // Play/Pause Button Action
                    playButtonAudio.addAction(UIAction { _ in
                        self.playPauseAudio(indexPath: indexPath, playButton: playButtonAudio, progressSlider: progressSliderAudio, timeLabel: timeLabelAudio)
                    }, for: .touchUpInside)
                    
                    progressSliderAudio.addAction(UIAction { _ in
                        self.sliderChanged(indexPath: indexPath, progressSlider: progressSliderAudio, timeLabel: timeLabelAudio)
                    }, for: .valueChanged)
                }
            }
        }
        
        if (!thumbChat.isEmpty && dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1" && dataMessages[indexPath.row]["lock"] as? String != "2") {
            if let listImages = groupImages[messageIdChat] {
                timeMessage.isHidden = true
                statusMessage.isHidden = true
                imageStared.isHidden = true
                topMarginText.constant = topMarginText.constant + 220
                var constTop = 35.0
                if dataMessages[indexPath.row][TypeDataMessage.is_forwarded] != nil && dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as! Int != 0 {
                    topMarginText.constant = topMarginText.constant + 20
                    constTop = 55.0
                }
                let listImageThumb: [UIImageView] = [UIImageView(), UIImageView(), UIImageView(), UIImageView()]
                for i in 0..<4 {
                    containerMessage.addSubview(listImageThumb[i])
                    listImageThumb[i].layer.cornerRadius = 5.0
                    listImageThumb[i].clipsToBounds = true
                    listImageThumb[i].contentMode = .scaleAspectFill
                    let widthHeightImage: CGFloat = 120
                    switch i {
                    case 0:
                        listImageThumb[i].anchor(top: containerMessage.topAnchor, left: containerMessage.leftAnchor, paddingTop: constTop, paddingLeft: 5, width: widthHeightImage, height: widthHeightImage)
                    case 1:
                        listImageThumb[i].anchor(top: containerMessage.topAnchor, left: listImageThumb[0].rightAnchor, right: containerMessage.rightAnchor, paddingTop: constTop, paddingLeft: 5, paddingRight: 5, width: widthHeightImage, height: widthHeightImage)
                    case 2:
                        listImageThumb[i].anchor(left: containerMessage.leftAnchor, bottom: containerMessage.bottomAnchor, paddingLeft: 5, paddingBottom: 5, width: widthHeightImage, height: widthHeightImage)
                    default:
                        listImageThumb[i].anchor(left: listImageThumb[2].rightAnchor, bottom: containerMessage.bottomAnchor, right: containerMessage.rightAnchor, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: widthHeightImage, height: widthHeightImage)
                    }
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if let dirPath = paths.first {
                        let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(listImages[i].thumbId)
                        if FileManager.default.fileExists(atPath: thumbURL.path) {
                            DispatchQueue.main.async {
                                let image : UIImage? =  {
                                    if let img = Nexilis.imageCache.object(forKey: listImages[i].thumbId as NSString) {
                                        return img
                                    }
                                    else if let img = UIImage(contentsOfFile: thumbURL.path)?.resize(target: CGSize(width: 500, height: 500)) {
                                            Nexilis.imageCache.setObject(img, forKey: listImages[i].thumbId as NSString)
                                            return img
                                    }
                                    return nil
                                }()
                                listImageThumb[i].image = image
                            }
                        } else if FileEncryption.shared.isSecureExists(filename: listImages[i].thumbId) {
                            do {
                                if var data = try FileEncryption.shared.readSecure(filename: listImages[i].thumbId) {
                                    let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                    if dataDecrypt != nil {
                                        data = dataDecrypt!
                                    }
                                    DispatchQueue.main.async {
                                        let image : UIImage? =  {
                                            if let img = Nexilis.imageCache.object(forKey: listImages[i].thumbId as NSString) {
                                                return img
                                            }
                                            else if let img = UIImage(data: data)?.resize(target: CGSize(width: 500, height: 500)) {
                                                Nexilis.imageCache.setObject(img, forKey: listImages[i].thumbId as NSString)
                                                return img
                                            }
                                            return nil
                                        }()
                                        listImageThumb[i].image = image
                                    }
                                }
                            } catch {
                                
                            }
                        } else {
                            Download().startHTTP(forKey: listImages[i].thumbId) { (name, progress) in
                                guard progress == 100 else {
                                    return
                                }
                                tableView.reloadRows(at: [indexPath], with: .none)
                            }
                        }
                        
                        let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(listImages[i].imageId)
                        if !FileManager.default.fileExists(atPath: imageURL.path) && !FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
                            let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
                            let blurEffectView = UIVisualEffectView(effect: blurEffect)
                            blurEffectView.frame = CGRect(x: 0, y: 0, width: listImageThumb[i].frame.size.width, height: listImageThumb[i].frame.size.height)
                            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                            listImageThumb[i].addSubview(blurEffectView)
                        }
                        
                    }
                    let containerTimeStatus = UIView()
                    listImageThumb[i].addSubview(containerTimeStatus)
                    containerTimeStatus.anchor(bottom: listImageThumb[i].bottomAnchor, right: listImageThumb[i].rightAnchor, height: 15)
                    let widthcontainerTimeStatus = containerTimeStatus.widthAnchor.constraint(equalToConstant: 50)
                    widthcontainerTimeStatus.isActive = true
                    containerTimeStatus.layer.cornerRadius = 5.0
                    containerTimeStatus.layer.masksToBounds = true
                    containerTimeStatus.backgroundColor = .black.withAlphaComponent(0.15)
                    
                    let timeInImage = UILabel()
                    containerTimeStatus.addSubview(timeInImage)
                    let date = Date(milliseconds: Int64(listImages[i].time) ?? 100)
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                    timeInImage.text = formatter.string(from: date as Date)
                    timeInImage.textColor = .white
                    timeInImage.font = UIFont.systemFont(ofSize: 10 + offset(), weight: .medium)
                    
                    if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                        let statusInImage = UIImageView()
                        containerTimeStatus.addSubview(statusInImage)
                        statusInImage.anchor(right: containerTimeStatus.rightAnchor, centerY: containerTimeStatus.centerYAnchor, width: 15, height: 15)
                        if listImages[i].status == "0" {
                            statusMessage.image = UIImage(systemName: "xmark.circle")!.withTintColor(UIColor.red, renderingMode: .alwaysOriginal)
                        } else if listImages[i].status == "1" {
                            statusMessage.image = UIImage(systemName: "clock.arrow.circlepath")!.withTintColor(UIColor.lightGray, renderingMode: .alwaysOriginal)
                        } else if listImages[i].status == "2"  {
                            statusInImage.image = UIImage(named: "checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.white)
                        } else if listImages[i].status == "3" {
                            statusInImage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.white)
                        } else {
                            statusInImage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
                        }
                        timeInImage.anchor(right: statusInImage.leftAnchor, centerY: containerTimeStatus.centerYAnchor, height: 15)
                    } else {
                        timeInImage.anchor(right: containerTimeStatus.rightAnchor, paddingRight: 5, centerY: containerTimeStatus.centerYAnchor, height: 15)
                        widthcontainerTimeStatus.constant = widthcontainerTimeStatus.constant - 10
                    }
                    
                    if listImages[i].dataMessage["is_stared"] as? String == "1" {
                        let iconStar = UIImageView()
                        containerTimeStatus.addSubview(iconStar)
                        iconStar.anchor(right: timeInImage.leftAnchor, paddingRight: 2, centerY: containerTimeStatus.centerYAnchor, width: 15, height: 15)
                        widthcontainerTimeStatus.constant = widthcontainerTimeStatus.constant + 15
                        iconStar.image = UIImage(systemName: "star.fill")
                        iconStar.tintColor = .white
                    }
                    
                    if !copySession && !forwardSession && !deleteSession {
                        let objectTap = ObjectGesture(target: self, action: #selector(imageGroupingTapped(_:)))
                        listImageThumb[i].isUserInteractionEnabled = true
                        listImageThumb[i].addGestureRecognizer(objectTap)
                        objectTap.indexImageTapped = i
                        objectTap.listImageFromGrouping = listImages
                        objectTap.isInitiator = dataMessages[indexPath.row]["f_pin"] as? String == idMe
                    }
                }
                if  listImages.count > 4 {
                    let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
                    let blurEffectView = UIVisualEffectView(effect: blurEffect)
                    blurEffectView.frame = CGRect(x: 0, y: 0, width: listImageThumb[3].frame.size.width, height: listImageThumb[3].frame.size.height)
                    blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    listImageThumb[3].addSubview(blurEffectView)
                    
                    let countRestImages = UILabel()
                    listImageThumb[3].addSubview(countRestImages)
                    countRestImages.anchor(centerX: listImageThumb[3].centerXAnchor, centerY: listImageThumb[3].centerYAnchor)
                    countRestImages.font = UIFont.systemFont(ofSize: 30, weight: .medium)
                    countRestImages.text = "+\(listImages.count - 3)"
                    countRestImages.textColor = .white
                }
            } else {
                let getHeightImage = ListGroupImages.getImageSize(image: thumbChat, screenWidth: self.view.frame.size.width * 0.6, screenHeight: 305)!.height
                let getWidthImage = ListGroupImages.getImageSize(image: thumbChat, screenWidth: self.view.frame.size.width * 0.6, screenHeight: 305)!.width
                topMarginText.constant = topMarginText.constant + (getHeightImage < 40 ? 40 : getHeightImage)
                
                containerMessage.addSubview(imageThumb)
                imageThumb.translatesAutoresizingMaskIntoConstraints = false
                imageThumb.frame = CGRect(x: 0, y: 0, width: getWidthImage, height: getHeightImage)
                let data = queryMessageReply(message_id: reffChat)
                if (reffChat.isEmpty || data.count == 0) && (dataMessages[indexPath.row][TypeDataMessage.is_forwarded] == nil || dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as! Int == 0) {
                    imageThumb.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 37).isActive = true
                }
                imageThumb.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                imageThumb.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                imageThumb.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                imageThumb.widthAnchor.constraint(equalToConstant: getWidthImage).isActive = true
                imageThumb.layer.cornerRadius = 5.0
                imageThumb.clipsToBounds = true
                imageThumb.contentMode = .scaleAspectFill
                
                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                if let dirPath = paths.first {
                    let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(thumbChat)
                    if FileManager.default.fileExists(atPath: thumbURL.path) {
                        DispatchQueue.main.async {
                            let image : UIImage? =  {
                                if let img = Nexilis.imageCache.object(forKey: thumbChat as NSString) {
                                    return img
                                }
                                else if let img = UIImage(contentsOfFile: thumbURL.path)?.resize(target: CGSize(width: 500, height: 500)) {
                                        Nexilis.imageCache.setObject(img, forKey: thumbChat as NSString)
                                        return img
                                }
                                return nil
                            }()
                            imageThumb.image = image
                        }
                    } else if FileEncryption.shared.isSecureExists(filename: thumbChat) {
                        do {
                            if var data = try FileEncryption.shared.readSecure(filename: thumbChat) {
                                let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                if dataDecrypt != nil {
                                    data = dataDecrypt!
                                }
                                DispatchQueue.main.async {
                                    let image : UIImage? =  {
                                        if let img = Nexilis.imageCache.object(forKey: thumbChat as NSString) {
                                            return img
                                        }
                                        else if let img = UIImage(data: data)?.resize(target: CGSize(width: 500, height: 500)) {
                                            Nexilis.imageCache.setObject(img, forKey: thumbChat as NSString)
                                            return img
                                        }
                                        return nil
                                    }()
                                    imageThumb.image = image
                                }
                            }
                        } catch {
                            
                        }
                    } else {
                        Download().startHTTP(forKey: thumbChat) { (name, progress) in
                            guard progress == 100 else {
                                return
                            }
                            tableView.reloadRows(at: [indexPath], with: .none)
                        }
                    }
                    
                    let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(imageChat)
                    if !FileManager.default.fileExists(atPath: imageURL.path) && !FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
                        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
                        let blurEffectView = UIVisualEffectView(effect: blurEffect)
                        blurEffectView.frame = CGRect(x: 0, y: 0, width: imageThumb.frame.size.width, height: imageThumb.frame.size.height)
                        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                        imageThumb.addSubview(blurEffectView)
                        if !imageChat.isEmpty {
                            let imageDownload = UIImageView(image: UIImage(systemName: "arrow.down.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .default)))
                            imageThumb.addSubview(blurEffectView)
                            imageThumb.addSubview(imageDownload)
                            imageDownload.tintColor = .black.withAlphaComponent(0.3)
                            imageDownload.translatesAutoresizingMaskIntoConstraints = false
                            imageDownload.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                            imageDownload.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                        }
                    }
                    
                }
                
                if (videoChat != "" && gifChat.isEmpty) {
                    let imagePlay = UIImageView(image: UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .default))?.imageWithInsets(insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))?.withTintColor(.white))
                    imagePlay.circle()
                    imageThumb.addSubview(imagePlay)
                    imagePlay.backgroundColor = .black.withAlphaComponent(0.3)
                    imagePlay.translatesAutoresizingMaskIntoConstraints = false
                    imagePlay.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                    imagePlay.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                } else if !gifChat.isEmpty {
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if let dirPath = paths.first {
                        let gifURL = URL(fileURLWithPath: dirPath).appendingPathComponent(gifChat)
                        if !FileManager.default.fileExists(atPath: gifURL.path) && !FileEncryption.shared.isSecureExists(filename: gifChat) {
                            Download().startHTTP(forKey: gifChat) { (name, progress) in
                                guard progress == 100 else {
                                    return
                                }
                                tableView.reloadRows(at: [indexPath], with: .none)
                            }
                        } else {
                            imageThumb.addSubview(imageGif)
                            imageGif.translatesAutoresizingMaskIntoConstraints = false
                            imageGif.anchor(top: imageThumb.topAnchor, left: imageThumb.leftAnchor, bottom: imageThumb.bottomAnchor, right: imageThumb.rightAnchor)
                            if FileManager.default.fileExists(atPath: gifURL.path) {
                                imageGif.image = SDAnimatedImage(contentsOfFile: gifURL.path)
//                                imageGif.shouldCustomLoopCount = true
//                                imageGif.animationRepeatCount = 4
                            } else if FileEncryption.shared.isSecureExists(filename: gifChat){
                                do {
                                    if var data = try FileEncryption.shared.readSecure(filename: gifChat) {
                                        let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                        if dataDecrypt != nil {
                                            data = dataDecrypt!
                                        }
                                        if let imageData = SDAnimatedImage(data: data) {
                                            imageGif.image = imageData
    //                                        imageGif.shouldCustomLoopCount = true
    //                                        imageGif.animationRepeatCount = 4
                                        }
                                    }
                                }
                                catch {
                                    print("Error reading secure file")
                                }
                            }
                        }
                    }
                }
                
                if (dataMessages[indexPath.row]["progress"] as! Double != 100.0 && dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                    let container = UIView()
                    imageThumb.addSubview(container)
                    container.translatesAutoresizingMaskIntoConstraints = false
                    container.bottomAnchor.constraint(equalTo: imageThumb.bottomAnchor, constant: -10).isActive = true
                    container.leadingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: 10).isActive = true
                    container.widthAnchor.constraint(equalToConstant: 30).isActive = true
                    container.heightAnchor.constraint(equalToConstant: 30).isActive = true
                    container.backgroundColor = .white.withAlphaComponent(0.1)
                    let circlePath = UIBezierPath(arcCenter: CGPoint(x: 10, y: 20), radius: 15, startAngle: -(.pi / 2), endAngle: .pi * 2, clockwise: true)
                    let trackShape = CAShapeLayer()
                    trackShape.path = circlePath.cgPath
                    trackShape.fillColor = UIColor.black.withAlphaComponent(0.3).cgColor
                    trackShape.lineWidth = 3
                    trackShape.strokeColor = UIColor.blueBubbleColor.withAlphaComponent(0.3).cgColor
                    container.backgroundColor = .clear
                    container.layer.addSublayer(trackShape)
                    let shapeLoading = CAShapeLayer()
                    shapeLoading.path = circlePath.cgPath
                    shapeLoading.fillColor = UIColor.clear.cgColor
                    shapeLoading.lineWidth = 3
                    shapeLoading.strokeEnd = 0
                    shapeLoading.strokeColor = UIColor.blueBubbleColor.cgColor
                    container.layer.addSublayer(shapeLoading)
                    let imageupload = UIImageView(image: UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                    imageupload.tintColor = .white
                    container.addSubview(imageupload)
                    imageupload.translatesAutoresizingMaskIntoConstraints = false
                    imageupload.bottomAnchor.constraint(equalTo: imageThumb.bottomAnchor, constant: -10).isActive = true
                    imageupload.leadingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: 10).isActive = true
                    imageupload.widthAnchor.constraint(equalToConstant: 20).isActive = true
                    imageupload.heightAnchor.constraint(equalToConstant: 20).isActive = true
                }
                
                if !copySession && !forwardSession && !deleteSession {
                    let objectTap = ObjectGesture(target: self, action: #selector(contentMessageTapped(_:)))
                    let sfs = (dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String) ?? ""
                    imageThumb.isUserInteractionEnabled = true
                    imageThumb.addGestureRecognizer(objectTap)
                    objectTap.image_id = imageChat
                    objectTap.video_id = videoChat
                    objectTap.gif_id = gifChat
                    objectTap.specFile = sfs
                    objectTap.imageView = imageThumb
                    objectTap.indexPath = indexPath
                }
            }
        }
        
        if (!fileChat.isEmpty && dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1" && dataMessages[indexPath.row]["lock"] as? String != "2") {
            topMarginText.constant = topMarginText.constant + 55
            
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            let arrExtFile = (originalMessageText.components(separatedBy: "|")[0]).split(separator: ".")
            let finalExtFile = arrExtFile[arrExtFile.count - 1]
            if let dirPath = paths.first {
                let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(fileChat)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    if let dataFile = try? Data(contentsOf: fileURL), textChat.isEmpty {
                        var sizeOfFile = Int(dataFile.count / 1000000)
                        if (sizeOfFile < 1) {
                            sizeOfFile = Int(dataFile.count / 1000)
                            if (finalExtFile.count > 4) {
                                messageText.text = "\(sizeOfFile) kB \u{2022} TXT"
                            }else {
                                messageText.text = "\(sizeOfFile) kB \u{2022} \(finalExtFile.uppercased())"
                            }
                        } else {
                            if (finalExtFile.count > 4) {
                                messageText.text = "\(sizeOfFile) MB \u{2022} TXT"
                            }else {
                                messageText.text = "\(sizeOfFile) MB \u{2022} \(finalExtFile.uppercased())"
                            }
                        }
                    }
                }
                else if FileEncryption.shared.isSecureExists(filename: fileChat) {
                    do {
                        if var dataFile = try FileEncryption.shared.readSecure(filename: fileChat), textChat.isEmpty {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: dataFile)
                            if dataDecrypt != nil {
                                dataFile = dataDecrypt!
                            }
                            var sizeOfFile = Int(dataFile.count / 1000000)
                            if (sizeOfFile < 1) {
                                sizeOfFile = Int(dataFile.count / 1000)
                                if (finalExtFile.count > 4) {
                                    messageText.text = "\(sizeOfFile) kB \u{2022} TXT"
                                }else {
                                    messageText.text = "\(sizeOfFile) kB \u{2022} \(finalExtFile.uppercased())"
                                }
                            } else {
                                if (finalExtFile.count > 4) {
                                    messageText.text = "\(sizeOfFile) MB \u{2022} TXT"
                                }else {
                                    messageText.text = "\(sizeOfFile) MB \u{2022} \(finalExtFile.uppercased())"
                                }
                            }
                        }
                    } catch {
                        
                    }
                }
            }
            
            containerMessage.addSubview(containerViewFile)
            containerViewFile.translatesAutoresizingMaskIntoConstraints = false
            let data = queryMessageReply(message_id: reffChat)
            if (reffChat.isEmpty || data.count == 0) && (dataMessages[indexPath.row][TypeDataMessage.is_forwarded] == nil || dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as! Int == 0) {
                containerViewFile.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 37).isActive = true
            } else {
                containerViewFile.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
            }
            containerViewFile.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            containerViewFile.bottomAnchor.constraint(equalTo:messageText.topAnchor, constant: -5).isActive = true
            containerViewFile.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
//            containerViewFile.heightAnchor.constraint(equalToConstant: 50).isActive = true
            containerViewFile.backgroundColor = .black.withAlphaComponent(0.2)
            containerViewFile.layer.cornerRadius = 5.0
            containerViewFile.clipsToBounds = true
            
            let imageFile = UIImageView(image: UIImage(systemName: "doc.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .bold, scale: .default)))
            containerViewFile.addSubview(imageFile)
            let nameFile = UILabel()
            containerViewFile.addSubview(nameFile)
            
            imageFile.translatesAutoresizingMaskIntoConstraints = false
            imageFile.leadingAnchor.constraint(equalTo: containerViewFile.leadingAnchor, constant: 5).isActive = true
            imageFile.trailingAnchor.constraint(equalTo: nameFile.leadingAnchor, constant: -5).isActive = true
            imageFile.centerYAnchor.constraint(equalTo: containerViewFile.centerYAnchor).isActive = true
            imageFile.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageFile.heightAnchor.constraint(equalToConstant: 30).isActive = true
            imageFile.tintColor = .docColor
            
            nameFile.translatesAutoresizingMaskIntoConstraints = false
            nameFile.centerYAnchor.constraint(equalTo: containerViewFile.centerYAnchor).isActive = true
            nameFile.widthAnchor.constraint(lessThanOrEqualToConstant: 200).isActive = true
            nameFile.font = UIFont.systemFont(ofSize: 12 + offset(), weight: .medium)
            nameFile.textColor = .white
            nameFile.text = originalMessageText.components(separatedBy: "|")[0]
            
            if (dataMessages[indexPath.row]["progress"] as! Double != 100.0) {
                let containerLoading = UIView()
                containerViewFile.addSubview(containerLoading)
                containerLoading.translatesAutoresizingMaskIntoConstraints = false
                containerLoading.centerYAnchor.constraint(equalTo: containerViewFile.centerYAnchor).isActive = true
                containerLoading.leadingAnchor.constraint(equalTo: nameFile.trailingAnchor, constant: 5).isActive = true
                containerLoading.trailingAnchor.constraint(equalTo: containerViewFile.trailingAnchor, constant: -5).isActive = true
                containerLoading.widthAnchor.constraint(equalToConstant: 30).isActive = true
                containerLoading.heightAnchor.constraint(equalToConstant: 30).isActive = true
                let circlePath = UIBezierPath(arcCenter: CGPoint(x: 15, y: 15), radius: 10, startAngle: -(.pi / 2), endAngle: .pi * 2, clockwise: true)
                let trackShape = CAShapeLayer()
                trackShape.path = circlePath.cgPath
                trackShape.fillColor = UIColor.clear.cgColor
                trackShape.lineWidth = 5
                trackShape.strokeColor = UIColor.blueBubbleColor.withAlphaComponent(0.3).cgColor
                containerLoading.layer.addSublayer(trackShape)
                let shapeLoading = CAShapeLayer()
                shapeLoading.path = circlePath.cgPath
                shapeLoading.fillColor = UIColor.clear.cgColor
                shapeLoading.lineWidth = 3
                shapeLoading.strokeEnd = 0
                shapeLoading.strokeColor = UIColor.secondaryColor.cgColor
                containerLoading.layer.addSublayer(shapeLoading)
                var imageupload = UIImageView(image: UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                if dataMessages[indexPath.row]["f_pin"] as? String != idMe {
                    imageupload = UIImageView(image: UIImage(systemName: "arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                    shapeLoading.strokeColor = UIColor.blueBubbleColor.cgColor
                }
                imageupload.tintColor = .white
                containerLoading.addSubview(imageupload)
                imageupload.translatesAutoresizingMaskIntoConstraints = false
                imageupload.centerYAnchor.constraint(equalTo: containerLoading.centerYAnchor).isActive = true
                imageupload.centerXAnchor.constraint(equalTo: containerLoading.centerXAnchor).isActive = true
            } else {
                nameFile.trailingAnchor.constraint(equalTo: containerViewFile.trailingAnchor, constant: -5).isActive = true
            }
            
            if !copySession && !forwardSession && !deleteSession {
                let objectTap = ObjectGesture(target: self, action: #selector(contentMessageTapped(_:)))
                let sfs = (dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String) ?? ""
                containerViewFile.addGestureRecognizer(objectTap)
                objectTap.containerFile = containerViewFile
                objectTap.labelFile = nameFile
                objectTap.file_id = fileChat
                objectTap.specFile = sfs
                objectTap.indexPath = indexPath
            }
        }
        
        let containerLinkMessage = UIView()
        var isLoadingShowLink = false
        if thumbChat.isEmpty && fileChat.isEmpty && !textChat.isEmpty {
            var text = ""
            let listTextSplitBreak = textChat.components(separatedBy: "\n")
            let indexFirstLinkSplitBreak = listTextSplitBreak.firstIndex(where: { $0.contains("www.") || $0.contains("http://") || $0.contains("https://") })
            if indexFirstLinkSplitBreak != nil {
                let listTextSplitSpace = listTextSplitBreak[indexFirstLinkSplitBreak!].components(separatedBy: " ")
                let indexFirstLinkSplitSpace = listTextSplitSpace.firstIndex(where: { ($0.starts(with: "www.") && $0.components(separatedBy: ".").count > 2) || ($0.starts(with: "http://") && $0.components(separatedBy: ".").count > 1) || ($0.starts(with: "https://") && $0.components(separatedBy: ".").count > 1) })
                if indexFirstLinkSplitSpace != nil {
                    text = listTextSplitSpace[indexFirstLinkSplitSpace!]
                }
            }
            if !text.isEmpty {
                isLoadingShowLink = true
                var dataURL = ""
                func showLink() {
                    if let data = try! JSONSerialization.jsonObject(with: dataURL.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                        let title = data["title"] as? String
                        let description = data["description"] as? String
                        let imageUrl = data["imageUrl"] as? String
                        let link = data["link"] as? String
                        
                        topMarginText.constant = topMarginText.constant + 85
                        
                        containerMessage.addSubview(containerLinkMessage)
                        containerLinkMessage.translatesAutoresizingMaskIntoConstraints = false
                        containerLinkMessage.leadingAnchor.constraint(equalTo:containerMessage.leadingAnchor, constant: 15).isActive = true
                        if dataMessages[indexPath.row]["attachment_flag"] as? String == "11" {
                            containerLinkMessage.bottomAnchor.constraint(equalTo: imageSticker.topAnchor, constant: -5).isActive = true
                        } else {
                            containerLinkMessage.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                        }
                        containerLinkMessage.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                        containerLinkMessage.heightAnchor.constraint(equalToConstant: 80.0).isActive = true
                        containerLinkMessage.backgroundColor = .gray.withAlphaComponent(0.2)
                        
                        let imagePreview = UIImageView()
                        if imageUrl != nil {
                            containerLinkMessage.addSubview(imagePreview)
                            imagePreview.translatesAutoresizingMaskIntoConstraints = false
                            imagePreview.leadingAnchor.constraint(equalTo: containerLinkMessage.leadingAnchor).isActive = true
                            imagePreview.bottomAnchor.constraint(equalTo: containerLinkMessage.bottomAnchor).isActive = true
                            imagePreview.topAnchor.constraint(equalTo: containerLinkMessage.topAnchor).isActive = true
                            imagePreview.widthAnchor.constraint(equalToConstant: 80.0).isActive = true
                            imagePreview.loadImageAsync(with: imageUrl)
                            imagePreview.contentMode = .scaleAspectFill
                            imagePreview.clipsToBounds = true
                        }
                        
                        let titlePreview = UILabel()
                        containerLinkMessage.addSubview(titlePreview)
                        titlePreview.translatesAutoresizingMaskIntoConstraints = false
                        if imageUrl != nil {
                            titlePreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
                        } else {
                            titlePreview.leadingAnchor.constraint(equalTo: containerLinkMessage.leadingAnchor, constant: 5.0).isActive = true
                        }
                        titlePreview.topAnchor.constraint(equalTo: containerLinkMessage.topAnchor, constant: 10.0).isActive = true
                        titlePreview.trailingAnchor.constraint(equalTo: containerLinkMessage.trailingAnchor, constant: -5.0).isActive = true
                        titlePreview.text = title
                        titlePreview.font = UIFont.systemFont(ofSize: 12.0 + offset(), weight: .bold)
                        titlePreview.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
                        
                        let descPreview = UILabel()
                        containerLinkMessage.addSubview(descPreview)
                        descPreview.translatesAutoresizingMaskIntoConstraints = false
                        if imageUrl != nil {
                            descPreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
                        } else {
                            descPreview.leadingAnchor.constraint(equalTo: containerLinkMessage.leadingAnchor, constant: 5.0).isActive = true
                        }
                        descPreview.topAnchor.constraint(equalTo: titlePreview.bottomAnchor).isActive = true
                        descPreview.trailingAnchor.constraint(equalTo: containerLinkMessage.trailingAnchor, constant: -5.0).isActive = true
                        descPreview.text = description
                        descPreview.font = UIFont.systemFont(ofSize: 12.0 + offset())
                        descPreview.textColor = .gray
                        descPreview.numberOfLines = 1
                        
                        let linkPreview = UILabel()
                        containerLinkMessage.addSubview(linkPreview)
                        linkPreview.translatesAutoresizingMaskIntoConstraints = false
                        if imageUrl != nil {
                            linkPreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
                        } else {
                            linkPreview.leadingAnchor.constraint(equalTo: containerLinkMessage.leadingAnchor, constant: 5.0).isActive = true
                        }
                        linkPreview.topAnchor.constraint(equalTo: descPreview.bottomAnchor, constant: 8.0).isActive = true
                        linkPreview.trailingAnchor.constraint(equalTo: containerLinkMessage.trailingAnchor, constant: -5.0).isActive = true
                        linkPreview.text = link
                        linkPreview.font = UIFont.systemFont(ofSize: 10.0 + offset())
                        linkPreview.textColor = .gray
                        linkPreview.numberOfLines = 1
                        
                        if dataMessages[indexPath.row][TypeDataMessage.is_forwarded] != nil && dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as! Int != 0 {
                            showForwardedSign()
                        }
                        
                        if !copySession && !forwardSession && !deleteSession {
                            let objectTap = ObjectGesture(target: self, action: #selector(tapMessageText(_:)))
                            objectTap.message_id = text
                            containerLinkMessage.addGestureRecognizer(objectTap)
                        }
                    }
                }
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select data_link from LINK_PREVIEW where link='\(text)'"), cursor.next() {
                            if let data = cursor.string(forColumnIndex: 0) {
                                dataURL = data
                            }
                            cursor.close()
                        }
                    } catch {
                        rollback.pointee = true
                        print("Access database error: \(error.localizedDescription)")
                    }
                })
                if !dataURL.isEmpty {
                    if let data = try! JSONSerialization.jsonObject(with: dataURL.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                        let imageUrl = data["imageUrl"] as? String
                        let link = data["link"]  as? String ?? ""
                        if imageUrl == nil || (link.contains("youtube.com") && link.contains("watch?v=") && !imageUrl!.contains("img.youtube.com/vi/")) {
                            dataURL = ""
                        }
                    }
                }
                if !dataURL.isEmpty {
                    if let data = try! JSONSerialization.jsonObject(with: dataURL.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                        let imageUrl = data["imageUrl"] as? String
                        let link = data["link"]  as? String ?? ""
                        if imageUrl == nil || (link.contains("youtube.com") && link.contains("watch?v=") && !imageUrl!.contains("img.youtube.com/vi/")) {
                            dataURL = ""
                        }
                    }
                }
                if dataURL.isEmpty {
                    let urlConfig = URLSessionConfiguration.default
                    let sessionDelegate = SelfSignedURLSessionDelegate()
                    let session = URLSession(configuration: urlConfig, delegate: sessionDelegate, delegateQueue: nil)
                    let slp = SwiftLinkPreview(session: session,
                                               workQueue: SwiftLinkPreview.defaultWorkQueue,
                                               responseQueue: DispatchQueue.main,
                                               cache: DisabledCache.instance)
                    let preview = slp.preview(text,
                                              onSuccess: { result in
                        let title = result.title?.trimmingCharacters(in: .whitespacesAndNewlines)
                                    .nilIfEmpty ?? URL(string: text)?.host ?? "Untitled"
                        let description: String
                        if text.contains("google.com") {
                            description = "" // special rule for google
                        } else {
                            description = result.description?.trimmingCharacters(in: .whitespacesAndNewlines)
                                .nilIfEmpty ?? ""
                        }
                        let imageUrl = self.youtubeThumbnail(from: text)
                            ?? result.image
                            ?? result.icon
                            ?? ""
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                var dataJson: [String: Any] = [:]
                                dataJson["title"] = title
                                dataJson["description"] = description
                                dataJson["imageUrl"] = imageUrl
                                dataJson["link"] = text
                                guard let json = String(data: try! JSONSerialization.data(withJSONObject: dataJson, options: []), encoding: String.Encoding.utf8) else {
                                    return
                                }
                                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "LINK_PREVIEW", cvalues: [
                                    "id" : "\(Date().currentTimeMillis().toHex())",
                                    "link" : text,
                                    "data_link" : json,
                                    "retry": 0
                                ], replace: true)
                                dataURL = json
                                showLink()
                                DispatchQueue.main.async {
                                    tableView.reloadRows(at: [indexPath], with: .none)
                                }
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                    }, onError: { error in
                    })
                } else {
                    showLink()
                }
            }
        }
        
        if (!reffChat.isEmpty) {
            let data = queryMessageReply(message_id: reffChat)
            if data.count != 0 {
                
                let containerReply = UIView()
                containerMessage.addSubview(containerReply)
                containerReply.translatesAutoresizingMaskIntoConstraints = false
                containerReply.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                containerReply.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 32).isActive = true
                if thumbChat != "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1") {
                    containerReply.bottomAnchor.constraint(equalTo: imageThumb.topAnchor, constant: -5).isActive = true
                } else if fileChat != "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1") {
                    containerReply.bottomAnchor.constraint(equalTo: containerViewFile.topAnchor, constant: -5).isActive = true
                } else if containerMessage.subviews.contains(containerLinkMessage) {
                    containerReply.bottomAnchor.constraint(equalTo: containerLinkMessage.topAnchor, constant: -5).isActive = true
                } else if dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1") {
                    containerReply.bottomAnchor.constraint(equalTo: imageSticker.topAnchor, constant: -5).isActive = true
                } else {
                    containerReply.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                }
                containerReply.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                let minHeightConstraint = containerReply.heightAnchor.constraint(greaterThanOrEqualToConstant: 50 + (self.offset()*3))
                minHeightConstraint.priority = .defaultHigh
                minHeightConstraint.isActive = true
                containerReply.backgroundColor = .black.withAlphaComponent(0.2)
                containerReply.layer.cornerRadius = 5
                containerReply.clipsToBounds = true
                
                if (thumbChat != "" || fileChat != "") && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1") {
                    topMarginText = messageText.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: topMarginText.constant + 50 + (self.offset()*3))
                }
                
                let leftReply = UIView()
                containerReply.addSubview(leftReply)
                leftReply.translatesAutoresizingMaskIntoConstraints = false
                leftReply.leadingAnchor.constraint(equalTo: containerReply.leadingAnchor).isActive = true
                leftReply.topAnchor.constraint(equalTo: containerReply.topAnchor).isActive = true
                leftReply.bottomAnchor.constraint(equalTo: containerReply.bottomAnchor).isActive = true
                leftReply.widthAnchor.constraint(equalToConstant: 3).isActive = true
                leftReply.layer.cornerRadius = 5
                leftReply.clipsToBounds = true
                leftReply.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
                
                let titleReply = UILabel()
                containerReply.addSubview(titleReply)
                titleReply.translatesAutoresizingMaskIntoConstraints = false
                titleReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
                titleReply.topAnchor.constraint(equalTo: containerReply.topAnchor, constant: 10).isActive = true
                titleReply.trailingAnchor.constraint(lessThanOrEqualTo: containerReply.trailingAnchor, constant: -20).isActive = true
                titleReply.font = UIFont.systemFont(ofSize: 12 + offset()).bold
                if (data["f_pin"] as? String == idMe) {
                    titleReply.text = "You".localized()
                    if dataMessages[indexPath.row]["f_pin"] as? String == idMe {
                        titleReply.textColor = .white
                        leftReply.backgroundColor = .white
                    } else {
                        titleReply.textColor = .mainColor
                        leftReply.backgroundColor = .mainColor
                    }
                } else {
                    if data["f_pin"] as? String != "-999" {
                        let dataProfile = getDataProfile(f_pin: data["f_pin"]  as? String ?? "", message_id: data["message_id"]  as? String ?? "")
                        titleReply.text = dataProfile["name"]
                    } else {
                        titleReply.text = "Bot"
                    }
                    if dataMessages[indexPath.row]["f_pin"] as? String == idMe {
                        titleReply.textColor = .white
                        leftReply.backgroundColor = .white
                    } else {
                        titleReply.textColor = .mainColor
                        leftReply.backgroundColor = .mainColor
                    }
                }
                
                let contentReply = UILabel()
                contentReply.numberOfLines = 2
                containerReply.addSubview(contentReply)
                contentReply.translatesAutoresizingMaskIntoConstraints = false
                contentReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
                contentReply.bottomAnchor.constraint(equalTo: containerReply.bottomAnchor, constant: -10).isActive = true
                let topConstraintContent = contentReply.topAnchor.constraint(equalTo: titleReply.bottomAnchor)
                topConstraintContent.priority = .defaultHigh
                topConstraintContent.isActive = true
                contentReply.font = UIFont.systemFont(ofSize: 10 + offset())
                let message_text = data["message_text"] as? String ?? ""
                let attachment_flag = data["attachment_flag"] as? String  ?? ""
                let thumb_chat = data["thumb_id"] as? String ?? ""
                let image_chat = data["image_id"] as? String ?? ""
                let video_chat = data["video_id"] as? String ?? ""
                let file_chat = data["file_id"] as? String ?? ""
                if (attachment_flag == "0" && thumb_chat == "") {
                    contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    contentReply.attributedText = message_text.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
                } else if (attachment_flag == "1" || image_chat != "") {
                    if (message_text.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                        contentReply.text = "📷 Photo".localized()
                    } else {
                        contentReply.attributedText = message_text.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
                    }
                } else if (attachment_flag == "2" || video_chat != "") {
                    if (message_text.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                        contentReply.text = "📹 Video".localized()
                    } else {
                        contentReply.attributedText = message_text.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
                    }
                } else if (attachment_flag == "6" || file_chat != ""){
                    contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    contentReply.text = "📄 \(message_text.components(separatedBy: "|")[0])"
                } else if (attachment_flag == "11") {
                    contentReply.text = "❤️ Sticker"
                } else if attachment_flag == "27" {
                    contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    contentReply.text = "📄 " + "Live Streaming".localized()
                } else if attachment_flag == "26" {
                    contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    contentReply.text = "📄 " + "Seminar".localized()
                }
                contentReply.textColor = .white.withAlphaComponent(0.8)
                
                if (attachment_flag == "1" || attachment_flag == "2" || image_chat != "" || video_chat != "") {
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if let dirPath = paths.first {
                        let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(thumb_chat)
                        let image : UIImage? =  {
                            if let img = Nexilis.imageCache.object(forKey: thumb_chat as NSString) {
                                return img
                            }
                            else if let img = UIImage(contentsOfFile: thumbURL.path)?.resize(target: CGSize(width: 500, height: 500)) {
                                Nexilis.imageCache.setObject(img, forKey: thumb_chat as NSString)
                                return img
                            }
                            return nil
                        }()
                        //                        let image = UIGraphicsRenderer.renderImageAt(url: thumbURL as NSURL, size: CGSize(width: 250, height: 250))
                        let imageThumb = UIImageView(image: image)
                        containerReply.addSubview(imageThumb)
                        imageThumb.layer.cornerRadius = 2.0
                        imageThumb.clipsToBounds = true
                        imageThumb.contentMode = .scaleAspectFill
                        imageThumb.translatesAutoresizingMaskIntoConstraints = false
                        imageThumb.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -10).isActive = true
                        imageThumb.centerYAnchor.constraint(equalTo: containerReply.centerYAnchor).isActive = true
                        imageThumb.widthAnchor.constraint(equalToConstant: 30).isActive = true
                        imageThumb.heightAnchor.constraint(equalToConstant: 30).isActive = true
                        
                        if (attachment_flag == "2") {
                            let imagePlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
                            imageThumb.addSubview(imagePlay)
                            imagePlay.clipsToBounds = true
                            imagePlay.translatesAutoresizingMaskIntoConstraints = false
                            imagePlay.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                            imagePlay.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                            imagePlay.widthAnchor.constraint(equalToConstant: 10).isActive = true
                            imagePlay.heightAnchor.constraint(equalToConstant: 10).isActive = true
                            imagePlay.tintColor = .white
                        }
                        titleReply.trailingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: -20).isActive = true
                        contentReply.trailingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: -20).isActive = true
                    }
                }
                if (attachment_flag == "11") {
                    let imageSticker = UIImageView(image: UIImage(named: (message_text.components(separatedBy: "/")[1]), in: Bundle.resourceBundle(for: Nexilis.self), with: nil))
                    containerReply.addSubview(imageSticker)
                    imageSticker.layer.cornerRadius = 2.0
                    imageSticker.clipsToBounds = true
                    imageSticker.translatesAutoresizingMaskIntoConstraints = false
                    imageSticker.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -10).isActive = true
                    imageSticker.centerYAnchor.constraint(equalTo: containerReply.centerYAnchor).isActive = true
                    imageSticker.widthAnchor.constraint(equalToConstant: 30).isActive = true
                    imageSticker.heightAnchor.constraint(equalToConstant: 30).isActive = true
                    titleReply.trailingAnchor.constraint(equalTo: imageSticker.leadingAnchor, constant: -20).isActive = true
                    contentReply.trailingAnchor.constraint(equalTo: imageSticker.leadingAnchor, constant: -20).isActive = true
                }
                
                if !copySession && !forwardSession && !deleteSession {
                    let objectTap = ObjectGesture(target: self, action: #selector(contentMessageTapped(_:)))
                    containerReply.addGestureRecognizer(objectTap)
                    objectTap.indexPath = indexPath
                    objectTap.message_id = data["message_id"]  as? String ?? ""
                }
            }
        }
        
        if dataMessages[indexPath.row][TypeDataMessage.is_forwarded] != nil && dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as! Int != 0 && !isLoadingShowLink {
            showForwardedSign()
        }
        
        func showForwardedSign() {
            topMarginText.constant = topMarginText.constant + 20
            
            let containerForwarded = UIView()
            containerMessage.addSubview(containerForwarded)
            containerForwarded.translatesAutoresizingMaskIntoConstraints = false
            containerForwarded.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            containerForwarded.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 32).isActive = true
            containerForwarded.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
            containerForwarded.heightAnchor.constraint(equalToConstant: 20).isActive = true
            if thumbChat != "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1") {
                if groupImages[messageIdChat] == nil {
                    containerForwarded.bottomAnchor.constraint(equalTo: imageThumb.topAnchor, constant: -5).isActive = true
                }
            } else if fileChat != "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1") {
                containerForwarded.bottomAnchor.constraint(equalTo: containerViewFile.topAnchor, constant: -5).isActive = true
            } else if containerMessage.subviews.contains(containerLinkMessage) {
                containerForwarded.bottomAnchor.constraint(equalTo: containerLinkMessage.topAnchor, constant: -5).isActive = true
            } else if dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1") {
                containerForwarded.bottomAnchor.constraint(equalTo: imageSticker.topAnchor, constant: -5).isActive = true
            }
            
            let imageForwarded = UIImageView()
            containerForwarded.addSubview(imageForwarded)
            imageForwarded.anchor(top: containerForwarded.topAnchor, left: containerForwarded.leftAnchor, width: 15, height: 15)
            imageForwarded.image = UIImage(systemName: "arrowshape.turn.up.right.fill")
            imageForwarded.tintColor = .gray
            
            let titleForwarded = UILabel()
            containerForwarded.addSubview(titleForwarded)
            titleForwarded.anchor(top: containerForwarded.topAnchor, left: imageForwarded.rightAnchor, right: containerForwarded.rightAnchor, height: 15)
            titleForwarded.font = .systemFont(ofSize: 15)
            let textForwarded = "Forwarded".localized()
            titleForwarded.attributedText = " $\(textForwarded)$".richText()
        }
        
        if messageText.isDescendant(of: containerMessage) {
            var addTopMargin = true
            if !reffChat.isEmpty && dataMessages[indexPath.row]["message_scope_id"]  as? String ?? "" != MessageScope.FORM {
                let data = queryMessageReply(message_id: reffChat)
                if data.count != 0 && (topMarginText.constant == 32.0 || topMarginText.constant == 100.0) {
                    addTopMargin = false
                }
            }
            if addTopMargin{
                topMarginText.isActive = true
            }
        }
        
        return cellMessage
    }
    
    func youtubeThumbnail(from url: String) -> String? {
        guard let url = URL(string: url) else { return nil }
        let host = url.host ?? ""
        
        if host.contains("youtube.com"),
           let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let videoId = queryItems.first(where: { $0.name == "v" })?.value {
            return "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"
        }
        
        if host.contains("youtu.be") {
            let videoId = url.lastPathComponent
            return "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"
        }
        
        return nil
    }
    
    func playPauseAudio(indexPath: IndexPath, playButton: UIButton, progressSlider: UISlider, timeLabel: UILabel) {
        guard let audioPlayer = audioPlayers[indexPath] else { return }

        if audioPlayer.isPlaying {
            // Pause Audio
            audioPlayer.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            timers[indexPath]?.invalidate()
        } else {
            // Stop other players if one is already playing
            if let currentPlayingIndexPath = playingIndexPath, let currentAudioPlayer = audioPlayers[currentPlayingIndexPath] {
                if currentPlayingIndexPath != indexPath {
                    currentAudioPlayer.pause()
                    timers[currentPlayingIndexPath]?.invalidate()
                    timers[currentPlayingIndexPath] = nil
                    audioPlayers[currentPlayingIndexPath] = nil
                    tableChatView.reloadRows(at: [currentPlayingIndexPath], with: .none)
                }
            }
            
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                
            }

            // Play new audio
            audioPlayer.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            playingIndexPath = indexPath

            // Start timer to update progress
            timers[indexPath] = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                progressSlider.value = Float(audioPlayer.currentTime)
                timeLabel.text = self.formatTime(audioPlayer.currentTime)
            }
        }
    }
    
    func sliderChanged(indexPath: IndexPath, progressSlider: UISlider, timeLabel: UILabel) {
        guard let audioPlayer = audioPlayers[indexPath] else { return }
        audioPlayer.currentTime = TimeInterval(progressSlider.value)
        timeLabel.text = formatTime(audioPlayer.currentTime)
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let roundedTime = time.rounded(.up)
        let minutes = Int(roundedTime) / 60
        let seconds = Int(roundedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let finishedIndexPath = audioPlayers.first(where: { $0.value == player })?.key {
           DispatchQueue.main.async {
               self.timers[finishedIndexPath]?.invalidate()
               self.timers[finishedIndexPath] = nil
               self.playingIndexPath = nil
               self.audioPlayers[finishedIndexPath] = nil
               self.tableChatView.reloadRows(at: [finishedIndexPath], with: .none)
           }
        }
    }
    
    @objc func imageGroupingTapped(_ sender: ObjectGesture) {
        let listGroupingImages = ListGroupImages()
        listGroupingImages.imageTapped = sender.indexImageTapped
        listGroupingImages.listGroupingImages = sender.listImageFromGrouping
        listGroupingImages.titleName = titleText
        listGroupingImages.isInitiator = sender.isInitiator
        listGroupingImages.isPersonal = false
        listGroupingImages.updateEditor = { [self] updatedData, replyData, isUpdateDelete in
            if replyData.count == 0 {
                if updatedData.count != 0 && !isUpdateDelete {
                    groupImages[sender.listImageFromGrouping[0].messageId] = updatedData
                } else if updatedData.count > 0 {
                    let deletedForEveryoneData = updatedData.filter({ $0.dataMessage["lock"] as? String == "1" })
                    if deletedForEveryoneData.count != 0 {
                        if groupImages[sender.listImageFromGrouping[0].messageId] != nil {
                            var dataWillEmpty = updatedData
                            while dataWillEmpty.count > 0 {
                                if let lastIdx = dataWillEmpty.lastIndex(where: { $0.dataMessage["lock"] as? String == "1" }) {
                                    if let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == sender.listImageFromGrouping[0].messageId }) {
                                        if dataWillEmpty[lastIdx].messageId == sender.listImageFromGrouping[0].messageId {
                                            self.dataMessages.remove(at: idx)
                                            self.dataMessages.insert(dataWillEmpty[lastIdx].dataMessage, at: idx)
                                        } else {
                                            self.dataMessages.insert(dataWillEmpty[lastIdx].dataMessage, at: idx + 1)
                                        }
                                        let subData = Array(updatedData[lastIdx+1..<dataWillEmpty.count])
                                        if subData.count >= 4 {
                                            groupImages[subData[0].messageId] = subData
                                            self.dataMessages.insert(subData[0].dataMessage, at: lastIdx + 1)
                                        } else {
                                            if subData.count > 0 {
                                                self.dataMessages.insert(contentsOf: subData.map({ $0.dataMessage }), at: idx + (dataWillEmpty[lastIdx].messageId == sender.listImageFromGrouping[0].messageId ? 1 : 2))
                                            }
                                        }
                                    }
                                    dataWillEmpty.removeSubrange(lastIdx..<dataWillEmpty.count)
                                } else if dataWillEmpty.count >= 4 {
                                    groupImages[dataWillEmpty[0].messageId] = dataWillEmpty
                                    dataWillEmpty.removeAll()
                                } else {
                                    if let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == sender.listImageFromGrouping[0].messageId }) {
                                        self.dataMessages.remove(at: idx)
                                        self.dataMessages.insert(contentsOf: dataWillEmpty.map({ $0.dataMessage }), at: idx)
                                        groupImages.removeValue(forKey: sender.listImageFromGrouping[0].messageId)
                                    }
                                    dataWillEmpty.removeAll()
                                }
                            }
                        } else {
                            
                        }
                    } else {
                        if updatedData.count >= 4 {
                            if updatedData[0].messageId == sender.listImageFromGrouping[0].messageId {
                                groupImages[sender.listImageFromGrouping[0].messageId] = updatedData
                            } else {
                                if let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == sender.listImageFromGrouping[0].messageId }) {
                                    self.dataMessages.remove(at: idx)
                                    self.dataMessages.insert(updatedData[0].dataMessage, at: idx)
                                    groupImages.removeValue(forKey: sender.listImageFromGrouping[0].messageId)
                                    groupImages[updatedData[0].messageId] = updatedData
                                }
                            }
                        } else {
                            if let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == sender.listImageFromGrouping[0].messageId }) {
                                groupImages.removeValue(forKey: sender.listImageFromGrouping[0].messageId)
                                self.dataMessages.remove(at: idx)
                                let dataMessageInGrouping = updatedData.map({ $0.dataMessage })
                                self.dataMessages.insert(contentsOf: dataMessageInGrouping, at: idx)
                            }
                        }
                    }
                } else {
                    groupImages.removeValue(forKey: sender.listImageFromGrouping[0].messageId)
                    if let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == sender.listImageFromGrouping[0].messageId }) {
                        self.dataMessages.remove(at: idx)
                    }
                }
                DispatchQueue.main.async { [self] in
                    tableChatView.reloadData()
                }
            } else if replyData.count != 0 {
                handleReply(indexPath: IndexPath(row: 0, section: 0), dataMessagesImage: replyData)
            }
        }
        self.navigationController?.pushViewController(listGroupingImages, animated: true)
    }
    
    @objc func tapAck(_ sender: ObjectGesture) {
        let indexPath = sender.indexPath
        let dataMessages = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == dataDates[indexPath.section]})
        if dataMessages[indexPath.row]["status"]  as? String ?? "" == "8" {
            return
        }
        if !CheckConnection.isConnectedToNetwork() || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        DispatchQueue.global().async {
            var opposite_pin = self.dataGroup["group_id"]  as? String ?? ""
            if (self.dataTopic["chat_id"]  as? String ?? "" != "") {
                opposite_pin = self.dataTopic["chat_id"]  as? String ?? ""
            }
            let result = Nexilis.write(message: CoreMessage_TMessageBank.getAckLocationMessage(f_pin: dataMessages[indexPath.row]["f_pin"]  as? String ?? "", message_id: dataMessages[indexPath.row]["message_id"]  as? String ?? "", l_pin: opposite_pin, server_date: "\(Date().currentTimeMillis())", message_scope_id: dataMessages[indexPath.row]["message_scope_id"]  as? String ?? "", longitude: self.longitude, latitude: self.latitude, description: ""))
            if result != nil {
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                            "status" : "8"
                        ], _where: "message_id = '\(dataMessages[indexPath.row]["message_id"]  as? String ?? "")'")
                    } catch {
                        rollback.pointee = true
                        print("Access database error: \(error.localizedDescription)")
                    }
                })
                DispatchQueue.main.async {
                    if let index = self.dataMessages.firstIndex(where: {$0["message_id"] as? String == dataMessages[indexPath.row]["message_id"] as? String}) {
                        self.dataMessages[index]["status"] = "8"
                        let section = self.dataDates.firstIndex(of: self.dataMessages[index]["chat_date"]  as? String ?? "")
                        let row = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataDates[section!]}).firstIndex(where: { $0["message_id"]  as? String ?? "" == self.dataMessages[index]["message_id"]  as? String ?? ""})
                        if row != nil && section != nil {
                            self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                        }
                        self.view.makeToast("Confirmation Success.".localized(), duration: 3)
                    }
                }
            }
        }
    }
    
    @objc func contentMessageTapped(_ sender: ObjectGesture) {
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        func showMedia(data: Data? = nil, url: URL? = nil, type: Int = 0) {
            let image = UIImage(data: data ?? Data())
            let imageViewer = MediaViewerViewController()
            if type == 0 {
                imageViewer.media = .image(image ?? UIImage())
            } else if type == 1 {
                imageViewer.media = .video(url ?? URL(string: "")!)
            } else if type == 2 {
                imageViewer.media = .gif(UIImage.gifImageWithData(data ?? Data()) ?? UIImage())
            }
            
            let navigationController = UINavigationController(rootViewController: imageViewer)
            navigationController.defaultStyle()
            navigationController.view.backgroundColor = .clear
            navigationController.modalPresentationCapturesStatusBarAppearance = true
            navigationController.modalPresentationStyle = .overFullScreen
            
            let backAction = UIAction { _ in
                navigationController.dismiss(animated: true)
            }
            let backButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "chevron.backward"), primaryAction: backAction, menu: nil)
            imageViewer.navigationItem.leftBarButtonItem = backButton
            if Nexilis.checkingAccess(key: "secure_folder_share") || sender.specFile.contains("download") || sender.specFile.contains("share") {
                let shareAction = UIAction { _ in
                    var activityViewController = UIActivityViewController(activityItems: [""], applicationActivities: nil)
                    if type == 1 {
                        activityViewController = UIActivityViewController(activityItems: [url ?? URL(string: "")!], applicationActivities: nil)
                    } else {
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ImageSharedNexilis-\(Date().currentTimeMillis())" + ".jpeg")
                        try? data!.write(to: tempURL)
                        activityViewController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                    }
                    activityViewController.popoverPresentationController?.sourceView = imageViewer.view
                    imageViewer.present(activityViewController, animated: true, completion: nil)
                }
                let shareButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "square.and.arrow.up"), primaryAction: shareAction, menu: nil)
                imageViewer.navigationItem.rightBarButtonItem = shareButton
            }
            
            let name = (dataGroup["f_name"] as? String ?? "") + " (\(dataTopic["title"] as? String ?? ""))"
            imageViewer.title = name
            
            let transitionDelegate = ZoomTransitioningDelegate()
            transitionDelegate.originImageView = sender.imageView
            navigationController.transitioningDelegate = transitionDelegate
            self.transitioningDelegateRef = transitionDelegate
            
            present(navigationController, animated: true) {
                imageViewer.animateBackgroundIn()
            }
        }
        if (sender.image_id != "") {
            if let dirPath = paths.first {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.image_id)
                if FileManager.default.fileExists(atPath: imageURL.path) {
                    do {
                        showMedia(data: try Data(contentsOf: imageURL))
                    } catch {
                        
                    }
                } else if FileEncryption.shared.isSecureExists(filename: sender.image_id) {
                    do {
                        if var data = try FileEncryption.shared.readSecure(filename: sender.image_id) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                            if dataDecrypt != nil {
                                data = dataDecrypt!
                            }
                            showMedia(data: data)
                        }
                    }
                    catch {
                        print("Error reading secure file")
                    }
                } else {
                    for view in sender.imageView.subviews {
                        if view is UIImageView {
                            view.removeFromSuperview()
                        }
                    }
                    let activityIndicator = UIActivityIndicatorView(style: .large)
                    activityIndicator.color = .mainColor
                    activityIndicator.hidesWhenStopped = true
                    activityIndicator.center = CGPoint(x:sender.imageView.frame.width/2,
                                                       y: sender.imageView.frame.height/2)
                    activityIndicator.startAnimating()
                    sender.imageView.addSubview(activityIndicator)
                    Download().startHTTP(forKey: sender.image_id) { (name, progress) in
                        guard progress == 100 else {
                            return
                        }
                        DispatchQueue.main.async {
                            activityIndicator.stopAnimating()
                            self.tableChatView.reloadRows(at: [sender.indexPath], with: .none)
                        }
                    }
                }
            }
        } else if (sender.gif_id != "") {
            if let dirPath = paths.first {
                let gifURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.gif_id)
                if FileManager.default.fileExists(atPath: gifURL.path) {
                    do {
                        let data = try Data(contentsOf: gifURL)
                        showMedia(data: data, type: 2)
                    } catch {
                        
                    }
                } else if FileEncryption.shared.isSecureExists(filename: sender.gif_id) {
                    do {
                        if var secureData = try FileEncryption.shared.readSecure(filename: sender.gif_id) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: secureData)
                            if dataDecrypt != nil {
                                secureData = dataDecrypt!
                            }
                            showMedia(data: secureData, type: 2)
                        }
                    } catch {
                        
                    }
                }
            }
        } else if (sender.video_id != "") {
            if let dirPath = paths.first {
                let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.video_id)
                if FileManager.default.fileExists(atPath: videoURL.path) {
                    showMedia(url: videoURL, type: 1)
                } else if FileEncryption.shared.isSecureExists(filename: sender.video_id) {
                    do {
                        if var secureData = try FileEncryption.shared.readSecure(filename: sender.video_id) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: secureData)
                            if dataDecrypt != nil {
                                secureData = dataDecrypt!
                            }
                            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                            let tempPath = cachesDirectory.appendingPathComponent(sender.video_id)
                            try secureData.write(to: tempPath)
                            showMedia(url: tempPath, type: 1)
                        }
                    } catch {
                        
                    }
                } else {
                    if downloadList[sender.video_id] != nil && downloadList[sender.video_id] == sender.indexPath {
                        return
                    }
                    downloadList[sender.video_id] = sender.indexPath
                    for view in sender.imageView.subviews {
                        if view is UIImageView {
                            view.removeFromSuperview()
                        }
                    }
                    let container = UIView()
                    sender.imageView.addSubview(container)
                    container.translatesAutoresizingMaskIntoConstraints = false
                    container.centerXAnchor.constraint(equalTo: sender.imageView.centerXAnchor).isActive = true
                    container.centerYAnchor.constraint(equalTo: sender.imageView.centerYAnchor).isActive = true
                    container.widthAnchor.constraint(equalToConstant: 50).isActive = true
                    container.heightAnchor.constraint(equalToConstant: 50).isActive = true
                    let circlePath = UIBezierPath(arcCenter: CGPoint(x: 25, y: 25), radius: 20, startAngle: -(.pi / 2), endAngle: .pi * 2, clockwise: true)
                    let trackShape = CAShapeLayer()
                    trackShape.path = circlePath.cgPath
                    trackShape.fillColor = UIColor.clear.cgColor
                    trackShape.lineWidth = 10
                    trackShape.strokeColor = UIColor.mentionColor.withAlphaComponent(0.3).cgColor
                    container.backgroundColor = .clear
                    container.layer.addSublayer(trackShape)
                    let shapeLoading = CAShapeLayer()
                    shapeLoading.path = circlePath.cgPath
                    shapeLoading.fillColor = UIColor.clear.cgColor
                    shapeLoading.lineWidth = 10
                    shapeLoading.strokeEnd = 0
                    shapeLoading.strokeColor = UIColor.mentionColor.cgColor
                    container.layer.addSublayer(shapeLoading)
                    let imageDownload = UIImageView(image: UIImage(systemName: "arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                    imageDownload.tintColor = .white
                    container.addSubview(imageDownload)
                    imageDownload.translatesAutoresizingMaskIntoConstraints = false
                    imageDownload.centerXAnchor.constraint(equalTo: sender.imageView.centerXAnchor).isActive = true
                    imageDownload.centerYAnchor.constraint(equalTo: sender.imageView.centerYAnchor).isActive = true
                    imageDownload.widthAnchor.constraint(equalToConstant: 30).isActive = true
                    imageDownload.heightAnchor.constraint(equalToConstant: 30).isActive = true
                    Download().startHTTP(forKey: sender.video_id) { (name, progress) in
                        DispatchQueue.main.async {
                            guard progress == 100 else {
                                shapeLoading.strokeEnd = CGFloat(progress / 100)
                                return
                            }
                            let idx = self.dataMessages.firstIndex(where: { $0["video_id"]  as? String ?? "" == sender.video_id})
                            if idx != nil {
                                self.dataMessages[idx!]["progress"] = progress
                                self.tableChatView.reloadRows(at: [sender.indexPath], with: .none)
                            }
                        }
                    }
                }
            }
        } else if (sender.file_id != "") {
            func showFile(urlFile: URL) {
                let previewController = QLPreviewController()
                previewController.dataSource = self
                let vcHandleFile = UIViewController()
                let nc = UINavigationController(rootViewController: vcHandleFile)
                let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
                let navBarAppearance = UINavigationBarAppearance()
                nc.defaultStyle()
                navBarAppearance.configureWithOpaqueBackground()
                navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
                navBarAppearance.titleTextAttributes = attributes
                nc.navigationBar.standardAppearance = navBarAppearance
                nc.navigationBar.scrollEdgeAppearance = navBarAppearance
                let backAction = UIAction { _ in
                    nc.dismiss(animated: true)
                }
                let backButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "chevron.backward"), primaryAction: backAction, menu: nil)
                vcHandleFile.navigationItem.leftBarButtonItem = backButton
                if Nexilis.checkingAccess(key: "secure_folder_share") || sender.specFile.contains("download") || sender.specFile.contains("share") {
                    let shareAction = UIAction { _ in
                        let fileManager = FileManager.default
                        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(urlFile.lastPathComponent)
                        do {
                            if !fileManager.fileExists(atPath: tempURL.path) {
                                try fileManager.copyItem(at: urlFile, to: tempURL)
                            }
                            let activityViewController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                            activityViewController.popoverPresentationController?.sourceView = vcHandleFile.view
                            vcHandleFile.present(activityViewController, animated: true, completion: nil)
                        } catch {
                            
                        }
                    }
                    let shareButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "square.and.arrow.up"), primaryAction: shareAction, menu: nil)
                    vcHandleFile.navigationItem.rightBarButtonItem = shareButton
                }
                if let viewVc = vcHandleFile.view {
                    vcHandleFile.title = sender.labelFile.text
                    vcHandleFile.addChild(previewController)
                    previewController.dataSource = self
                    previewController.view.frame = CGRect(x: 0, y: 0, width: viewVc.bounds.size.width, height: viewVc.bounds.size.height)
                    previewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    viewVc.addSubview(previewController.view)
                    previewController.didMove(toParent: vcHandleFile)
                    
                    self.present(nc, animated: true)
                }
            }
            if let dirPath = paths.first {
                let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.file_id)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    self.previewItem = fileURL as NSURL
                    showFile(urlFile: fileURL)
                } else if FileEncryption.shared.isSecureExists(filename: sender.file_id) {
                    do {
                        if var docData = try FileEncryption.shared.readSecure(filename: sender.file_id) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: docData)
                            if dataDecrypt != nil {
                                docData = dataDecrypt!
                            }
                            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                            let tempPath = cachesDirectory.appendingPathComponent(sender.file_id)
                            try docData.write(to: tempPath)
                            self.previewItem = tempPath as NSURL
                            showFile(urlFile: tempPath)
                        }
                    }
                    catch {
                        
                    }
                } else {
                    if downloadList[sender.file_id] != nil && downloadList[sender.file_id] == sender.indexPath {
                        return
                    }
                    downloadList[sender.file_id] = sender.indexPath
                    for view in sender.containerFile.subviews {
                        if !(view is UIImageView) && !(view is UILabel) {
                            view.removeFromSuperview()
                        }
                    }
                    let containerLoading = UIView()
                    sender.containerFile.addSubview(containerLoading)
                    containerLoading.translatesAutoresizingMaskIntoConstraints = false
                    containerLoading.centerYAnchor.constraint(equalTo: sender.containerFile.centerYAnchor).isActive = true
                    containerLoading.leadingAnchor.constraint(equalTo: sender.labelFile.trailingAnchor, constant: 5).isActive = true
                    containerLoading.trailingAnchor.constraint(equalTo: sender.containerFile.trailingAnchor, constant: -5).isActive = true
                    containerLoading.widthAnchor.constraint(equalToConstant: 30).isActive = true
                    containerLoading.heightAnchor.constraint(equalToConstant: 30).isActive = true
                    let circlePath = UIBezierPath(arcCenter: CGPoint(x: 15, y: 15), radius: 10, startAngle: -(.pi / 2), endAngle: .pi * 2, clockwise: true)
                    let trackShape = CAShapeLayer()
                    trackShape.path = circlePath.cgPath
                    trackShape.fillColor = UIColor.clear.cgColor
                    trackShape.lineWidth = 5
                    trackShape.strokeColor = UIColor.mentionColor.withAlphaComponent(0.3).cgColor
                    containerLoading.layer.addSublayer(trackShape)
                    let shapeLoading = CAShapeLayer()
                    shapeLoading.path = circlePath.cgPath
                    shapeLoading.fillColor = UIColor.clear.cgColor
                    shapeLoading.lineWidth = 3
                    shapeLoading.strokeEnd = 0
                    shapeLoading.strokeColor = UIColor.mentionColor.cgColor
                    containerLoading.layer.addSublayer(shapeLoading)
                    let imageupload = UIImageView(image: UIImage(systemName: "arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                    imageupload.tintColor = .white
                    containerLoading.addSubview(imageupload)
                    imageupload.translatesAutoresizingMaskIntoConstraints = false
                    imageupload.centerYAnchor.constraint(equalTo: containerLoading.centerYAnchor).isActive = true
                    imageupload.centerXAnchor.constraint(equalTo: containerLoading.centerXAnchor).isActive = true
                    
                    Download().startHTTP(forKey: sender.file_id) { (name, progress) in
                        DispatchQueue.main.async {
                            guard progress == 100 else {
                                shapeLoading.strokeEnd = CGFloat(progress / 100)
                                return
                            }
                            let idx = self.dataMessages.firstIndex(where: { $0["file_id"]  as? String ?? "" == sender.file_id})
                            if idx != nil {
                                self.dataMessages[idx!]["progress"] = progress
                                self.tableChatView.reloadRows(at: [sender.indexPath], with: .none)
                            }
                        }
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == sender.message_id})
                if idx == nil {
                    return
                }
                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
                if section == nil {
                    return
                }
                let row = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataDates[section!]}).firstIndex(where: { $0["message_id"]  as? String ?? "" == self.dataMessages[idx!]["message_id"]  as? String ?? ""})
                if row == nil {
                    return
                }
                let indexPath = IndexPath(row: row!, section: section!)
                self.tableChatView.scrollToRow(at: indexPath, at: .middle, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let cell = self.tableChatView.cellForRow(at: indexPath) {
                        let containerMessage = cell.contentView.subviews[1]
                        let idMe = User.getMyPin() as String?
                        if (self.dataMessages[idx!]["f_pin"] as? String == idMe) {
                            containerMessage.backgroundColor = .blueBubbleColor.withAlphaComponent(0.3)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if (self.dataMessages[idx!]["attachment_flag"] as? String == "11") {
                                    containerMessage.backgroundColor = .clear
                                } else {
                                    containerMessage.backgroundColor = .blueBubbleColor
                                }
                            }
                        } else {
                            containerMessage.backgroundColor = .whiteBubbleColor.withAlphaComponent(0.3)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if (self.dataMessages[idx!]["attachment_flag"] as? String == "11") {
                                    containerMessage.backgroundColor = .clear
                                } else {
                                    containerMessage.backgroundColor = .whiteBubbleColor
                                }
                            }
                        }
                    }
                }
            }
        }
    }
        
    func highlightedText(for text: String, in range: Range<String.Index>, textView: UITextView) -> NSAttributedString {
        let mutableAttributedString = textView.attributedText!.mutableCopy() as! NSMutableAttributedString
        mutableAttributedString.addAttribute(.backgroundColor, value: UIColor.lightGray.withAlphaComponent(0.5), range: NSRange(range, in: text))
        return mutableAttributedString
    }
    
    func removeHighlightedText(for text: String, in range: Range<String.Index>, textView: UITextView) -> NSAttributedString {
        let mutableAttributedString = textView.attributedText!.mutableCopy() as! NSMutableAttributedString
        mutableAttributedString.removeAttribute(.backgroundColor, range: NSRange(range, in: text))
        return mutableAttributedString
    }
        
    @objc func tapMessageText(_ sender: ObjectGesture) {
        var stringURl = sender.message_id
        if stringURl.lowercased().starts(with: "www.") {
            stringURl = "https://" + stringURl.replacingOccurrences(of: "www.", with: "")
        }
        let app: UIApplication = UIApplication.shared
        var appURL: URL? = nil
        if let url = URL(string: stringURl) {
            if url.host?.contains("instagram.com") == true {
                // Convert to Instagram deep link
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let path = components.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
                    appURL = URL(string: "instagram://\(path)")
                }
            } else if url.host?.contains("x.com") == true || url.host?.contains("twitter.com") == true {
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let path = components.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
                    appURL = URL(string: "twitter://\(path)")
                }
            } else if url.host?.contains("youtube.com") == true || url.host?.contains("youtu.be") == true {
                appURL = URL(string: "youtube://\(url.absoluteString)")
            }
            if let appURL = appURL, app.canOpenURL(appURL) {
                app.open(appURL, options: [:]) { success in
                    if !success {
                        if Nexilis.checkingAccess(key: "secure_browser") {
                            APIS.openUrl(url: stringURl)
                        } else {
                            app.open(url)
                        }
                    }
                }
            } else {
                if Nexilis.checkingAccess(key: "secure_browser") {
                    APIS.openUrl(url: stringURl)
                } else {
                    app.open(url)
                }
            }
        }
    }
    
    //    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    //        if copySession || forwardSession || deleteSession {
    //            return nil
    //        }
    //        let idMe = User.getMyPin() as String?
    //        if (dataMessages[indexPath.row]["f_pin"] as? String != idMe) {
    //            return nil
    //        }
    //        let messageInfoVC = MessageInfo()
    //        self.navigationController?.show(messageInfoVC, sender: nil)
    //        return UISwipeActionsConfiguration()
    //    }
    //
    //    public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    //        if copySession || forwardSession || deleteSession {
    //            return nil
    //        }
    //        let action = UIContextualAction(style: .normal,
    //                                        title: "") { [weak self] (action, view, completionHandler) in
    //                                            self?.handleReply(indexPath: indexPath)
    //                                            completionHandler(true)
    //        }
    //        action.backgroundColor = .white
    //        action.image = UIImage(systemName: "arrowshape.turn.up.left.fill")?.withTintColor(.black, renderingMode: .alwaysOriginal)
    //        return UISwipeActionsConfiguration(actions: [action])
    //    }
    
    private func pinAllMessages(dataMessages: [[String: Any?]], isPinned: Int = -1) {
        var dataMessages = dataMessages
        dataMessages.sort {
            let firstPinned = Int64($0[TypeDataMessage.is_pinned] as? String ?? "0") ?? 0
            let secondPinned = Int64($1[TypeDataMessage.is_pinned] as? String ?? "0") ?? 0
            return firstPinned < secondPinned
        }
        if dataMessages.count != 0 {
            if !self.containerPin.isDescendant(of: self.view) && dataMessages.count != 0 {
                self.tableChatView.contentInset.top = 50
                
                self.view.addSubview(self.containerPin)
                self.containerPin.isUserInteractionEnabled = true
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewPinTapped))
                self.containerPin.addGestureRecognizer(tapGesture)
                self.containerPin.anchor(top: self.view.safeAreaLayoutGuide.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, height: 50)
                self.containerPin.backgroundColor = .mainColor
                
                if dataMessages.count > 1 {
                    self.containerPin.addSubview(self.signSelectedPin)
                    self.signSelectedPin.anchor(left: self.containerPin.leftAnchor, paddingLeft: 8, centerY: self.containerPin.centerYAnchor, width: 2, height: 30)
                    self.signSelectedPin.layer.cornerRadius = 1
                    self.signSelectedPin.clipsToBounds = true
                    self.signSelectedPin.alignment = .fill
                    self.signSelectedPin.axis = .vertical
                    self.signSelectedPin.distribution = .fill
                    self.signSelectedPin.spacing = dataMessages.count == 3 ? 1.5 : 2
                    
                    let heightSign: CGFloat = CGFloat((30 / dataMessages.count) - 1)
                    let widthSign: CGFloat = 2

                    for i in 0..<dataMessages.count {
                        let viewSign = UIView()
                        viewSign.backgroundColor = (i == (dataMessages.count - 1)) ? .white : .gray
                        viewSign.anchor(width: widthSign, height: heightSign)
                        viewSign.layer.cornerRadius = 1
                        viewSign.clipsToBounds = true
                        self.signSelectedPin.addArrangedSubview(viewSign)
                    }
                    self.nextPinShowed = dataMessages.count - 1
                }
                
                let contIconPin = UIImageView()
                self.containerPin.addSubview(contIconPin)
                contIconPin.anchor(left: self.containerPin.leftAnchor, paddingLeft: 15, centerY: self.containerPin.centerYAnchor, width: 30, height: 30)
                contIconPin.layer.cornerRadius = 8
                contIconPin.clipsToBounds = true
                contIconPin.backgroundColor = .gray
                contIconPin.image = UIImage(systemName: "pin.fill")?.imageWithInsets(insets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))?.withTintColor(.waGrayLight)
                
                self.containerPin.addSubview(textPin)
                self.textPin.anchor(left: contIconPin.rightAnchor, right: self.containerPin.rightAnchor, paddingLeft: 10, paddingRight: 10, centerY: self.containerPin.centerYAnchor)
                let chat = Chat.getMessageFromId(message_id: dataMessages[dataMessages.count - 1][TypeDataMessage.message_id] as? String ?? "")
                if chat.count > 0 {
                    let text = Utils.previewMessageText(chat: chat[0])
                    if let attributeText = text as? NSMutableAttributedString {
                        self.textPin.attributedText = attributeText
                    }
                }
                self.textPin.numberOfLines = 1
                self.textPin.textColor = .white
            } else {
                self.signSelectedPin.subviews.forEach({ $0.removeFromSuperview() })
                self.signSelectedPin.removeFromSuperview()
                var same = false
                if dataMessages.count > 1 {
                    self.containerPin.addSubview(self.signSelectedPin)
                    self.signSelectedPin.anchor(left: self.containerPin.leftAnchor, paddingLeft: 8, centerY: self.containerPin.centerYAnchor, width: 2, height: 30)
                    self.signSelectedPin.layer.cornerRadius = 1
                    self.signSelectedPin.clipsToBounds = true
                    self.signSelectedPin.alignment = .fill
                    self.signSelectedPin.axis = .vertical
                    self.signSelectedPin.distribution = .fill
                    self.signSelectedPin.spacing = dataMessages.count == 3 ? 1.5 : 2
                    
                    let heightSign: CGFloat = CGFloat((30 / dataMessages.count) - 1)
                    let widthSign: CGFloat = 2

                    for i in 0..<dataMessages.count {
                        let viewSign = UIView()
                        viewSign.backgroundColor = (i == (dataMessages.count - 1)) ? .white : .gray
                        viewSign.anchor(width: widthSign, height: heightSign)
                        viewSign.layer.cornerRadius = 1
                        viewSign.clipsToBounds = true
                        self.signSelectedPin.addArrangedSubview(viewSign)
                    }
                    if isPinned == -1 {
                        self.nextPinShowed = dataMessages.count - 1
                    } else if self.nextPinShowed != 0 {
                        if (self.nextPinShowed > isPinned) {
                            self.nextPinShowed-=1
                            same = true
                        } else if self.nextPinShowed == isPinned && dataMessages.count == 3 {
                            self.nextPinShowed-=2
                        }
                    } else if self.nextPinShowed != isPinned {
                        same = true
                    }
                } else if self.nextPinShowed != isPinned {
                    same = true
                }
                if !same{
                    let chat = Chat.getMessageFromId(message_id: dataMessages[dataMessages.count - 1][TypeDataMessage.message_id] as? String ?? "")
                    if chat.count > 0 {
                        let text = Utils.previewMessageText(chat: chat[0])
                        if let attributeText = text as? NSMutableAttributedString {
                            animateLabelTextChange(label: self.textPin, newText: attributeText.string)
                        }
                    }
                }
            }
        } else if self.containerPin.isDescendant(of: self.view) {
            self.containerPin.subviews.forEach({ $0.removeFromSuperview() })
            self.containerPin.removeFromSuperview()
            self.tableChatView.contentInset.top = 0
        }
    }
    
    @objc func viewPinTapped() {
        var dataMessagesPin = self.dataMessages.filter({ $0[TypeDataMessage.is_pinned] as? String ?? "0" != "0"})
        dataMessagesPin.sort {
            let firstPinned = Int64($0[TypeDataMessage.is_pinned] as? String ?? "0") ?? 0
            let secondPinned = Int64($1[TypeDataMessage.is_pinned] as? String ?? "0") ?? 0
            return firstPinned < secondPinned
        }
        let obj = ObjectGesture()
        obj.message_id = dataMessagesPin[nextPinShowed][TypeDataMessage.message_id] as? String ?? ""
        contentMessageTapped(obj)
        
        if dataMessagesPin.count > 0 {
            if nextPinShowed < dataMessagesPin.count - 1 {
                nextPinShowed+=1
            } else {
                nextPinShowed = 0
            }
            
            DispatchQueue.main.async {
                self.signSelectedPin.subviews.forEach({ $0.removeFromSuperview() })
                self.signSelectedPin.removeFromSuperview()
                self.containerPin.addSubview(self.signSelectedPin)
                self.signSelectedPin.anchor(left: self.containerPin.leftAnchor, paddingLeft: 8, centerY: self.containerPin.centerYAnchor, width: 2, height: 30)
                self.signSelectedPin.layer.cornerRadius = 1
                self.signSelectedPin.clipsToBounds = true
                self.signSelectedPin.alignment = .fill
                self.signSelectedPin.axis = .vertical
                self.signSelectedPin.distribution = .fill
                self.signSelectedPin.spacing = dataMessagesPin.count == 3 ? 1.5 : 2
                
                let heightSign: CGFloat = CGFloat((30 / dataMessagesPin.count) - 1)
                let widthSign: CGFloat = 2

                for i in 0..<dataMessagesPin.count {
                    let viewSign = UIView()
                    viewSign.backgroundColor = (i == self.nextPinShowed) ? .white : .gray
                    viewSign.anchor(width: widthSign, height: heightSign)
                    viewSign.layer.cornerRadius = 1
                    viewSign.clipsToBounds = true
                    self.signSelectedPin.addArrangedSubview(viewSign)
                }
                let chat = Chat.getMessageFromId(message_id: dataMessagesPin[dataMessagesPin.count - 1][TypeDataMessage.message_id] as? String ?? "")
                if chat.count > 0 {
                    let text = Utils.previewMessageText(chat: chat[0])
                    if let attributeText = text as? NSMutableAttributedString {
                        self.animateLabelTextChange(label: self.textPin, newText: attributeText.string)
                    }
                }
            }
        }
    }
    
    func animateLabelTextChange(label: UILabel, newText: String) {
        let animationDuration = 0.1
        UIView.animate(withDuration: animationDuration, animations: {
            label.transform = CGAffineTransform(translationX: 0, y: -10)
            label.alpha = 0
        }) { _ in
            // Change text after fade out
            label.attributedText = newText.richText(fontSize: 14, group_id: self.dataGroup["group_id"]  as? String ?? "")
            label.transform = CGAffineTransform(translationX: 0, y: 10)
            
            // Animate back to original position and fade in
            UIView.animate(withDuration: animationDuration) {
                label.transform = .identity
                label.alpha = 1
            }
        }
    }
    
    private func handleReply(indexPath: IndexPath, dataMessagesImage: [String: Any?] = [:], reffId: String = "") {
        var dataMessages = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == dataDates[indexPath.section]})
        if reffId.isEmpty {
            self.deleteReplyView()
            if dataMessagesImage.count != 0 {
                dataMessages = [dataMessagesImage]
            } else {
                self.textFieldSend.becomeFirstResponder()
            }
            self.reffId = dataMessages[indexPath.row]["message_id"] as? String
        } else {
            dataMessages = self.dataMessages.filter({ $0["message_id"]  as? String ?? "" == reffId })
            self.reffId = reffId
        }
        if dataMessages.count == 0  {
            self.deleteReplyView()
            return
        }
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.constraintTopTextField.constant = self.constraintTopTextField.constant + 50 + (self.offset()*3)
            if self.contraintBottomMention.constant > 0 {
                self.contraintBottomMention.constant = self.contraintBottomMention.constant + self.heightTextFieldSend.constant
            }
        }, completion: nil)
        if (self.currentIndexpath != nil) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.tableChatView.scrollToRow(at: IndexPath(row: self.currentIndexpath!.row, section: self.currentIndexpath!.section), at: .none, animated: false)
            }
        } else {
            self.tableChatView.scrollToBottom()
        }
        
        self.viewTextfield.addSubview(self.containerPreviewReply)
        self.containerPreviewReply.translatesAutoresizingMaskIntoConstraints = false
        self.containerPreviewReply.leadingAnchor.constraint(equalTo: self.viewTextfield.leadingAnchor).isActive = true
        self.containerPreviewReply.topAnchor.constraint(equalTo: self.viewTextfield.topAnchor).isActive = true
        if !self.containerLink.isDescendant(of: self.viewTextfield) {
            self.bottomAnchorPreviewReply = self.containerPreviewReply.bottomAnchor.constraint(equalTo: self.textFieldSend.topAnchor)
        } else {
            self.bottomAnchorPreviewReply = self.containerPreviewReply.bottomAnchor.constraint(equalTo: self.containerLink.topAnchor)
        }
        self.bottomAnchorPreviewReply.isActive = true
        self.containerPreviewReply.trailingAnchor.constraint(equalTo: self.viewTextfield.trailingAnchor).isActive = true
        self.containerPreviewReply.backgroundColor = .secondaryColor
        
        let leftReply = UIView()
        self.containerPreviewReply.addSubview(leftReply)
        leftReply.translatesAutoresizingMaskIntoConstraints = false
        leftReply.leadingAnchor.constraint(equalTo: self.viewTextfield.leadingAnchor).isActive = true
        leftReply.topAnchor.constraint(equalTo: self.containerPreviewReply.topAnchor).isActive = true
        leftReply.bottomAnchor.constraint(equalTo: self.containerPreviewReply.bottomAnchor).isActive = true
        leftReply.widthAnchor.constraint(equalToConstant: 3).isActive = true
        leftReply.backgroundColor = .orangeColor
        
        let titleReply = UILabel()
        self.containerPreviewReply.addSubview(titleReply)
        titleReply.translatesAutoresizingMaskIntoConstraints = false
        titleReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
        titleReply.topAnchor.constraint(equalTo: self.containerPreviewReply.topAnchor, constant: 10).isActive = true
        titleReply.font = UIFont.systemFont(ofSize: 12 + offset()).bold
        let idMe = User.getMyPin() as String?
        if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
            titleReply.text = "You".localized()
        } else {
            if dataMessages[indexPath.row]["f_pin"] as? String != "-999" {
                let dataPerson = self.getDataProfile(f_pin: dataMessages[indexPath.row]["f_pin"]  as? String ?? "", message_id: dataMessages[indexPath.row]["message_id"]  as? String ?? "")
                titleReply.text = dataPerson["name"]
            } else {
                titleReply.text = "Bot"
            }
        }
        titleReply.textColor = .orangeColor
        
        let contentReply = UILabel()
        self.containerPreviewReply.addSubview(contentReply)
        contentReply.translatesAutoresizingMaskIntoConstraints = false
        contentReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
        contentReply.topAnchor.constraint(equalTo: titleReply.bottomAnchor).isActive = true
        contentReply.trailingAnchor.constraint(equalTo: containerPreviewReply.trailingAnchor, constant: -20).isActive = true
        contentReply.font = UIFont.systemFont(ofSize: 10 + offset())
        let message_text = dataMessages[indexPath.row]["message_text"]  as? String ?? ""
        let attachment_flag = dataMessages[indexPath.row]["attachment_flag"]  as? String ?? ""
        let thumb_chat = dataMessages[indexPath.row]["thumb_id"]  as? String ?? ""
        let image_chat = dataMessages[indexPath.row]["image_id"]  as? String ?? ""
        let video_chat = dataMessages[indexPath.row]["video_id"]  as? String ?? ""
        let file_chat = dataMessages[indexPath.row]["file_id"]  as? String ?? ""
        if (attachment_flag == "0" && thumb_chat == "") {
            contentReply.attributedText = message_text.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
        } else if (attachment_flag == "1" || image_chat != "") {
            if (message_text.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                contentReply.text = "📷 Photo".localized()
            } else {
                contentReply.attributedText = message_text.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
            }
        } else if (attachment_flag == "2" || video_chat != "") {
            if (message_text.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                contentReply.text = "📹 Video".localized()
            } else {
                contentReply.attributedText = message_text.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
            }
        } else if (attachment_flag == "6" || file_chat != ""){
            contentReply.text = "📄 \(message_text.components(separatedBy: "|")[0])"
        } else if (attachment_flag == "11") {
            contentReply.text = "❤️ Sticker"
        } else if attachment_flag == "27" {
            contentReply.text = "📄 " + "Live Streaming".localized()
        } else if attachment_flag == "26" {
            contentReply.text = "📄 " + "Seminar".localized()
        }
        contentReply.textColor = .gray
        
        let buttonCancelReply = UIButton(type: .custom)
        self.containerPreviewReply.addSubview(buttonCancelReply)
        buttonCancelReply.translatesAutoresizingMaskIntoConstraints = false
        buttonCancelReply.trailingAnchor.constraint(equalTo: self.containerPreviewReply.trailingAnchor, constant: -10).isActive = true
        buttonCancelReply.centerYAnchor.constraint(equalTo: self.containerPreviewReply.centerYAnchor).isActive = true
        buttonCancelReply.setImage(UIImage(systemName: "xmark.circle" , withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default)), for: .normal)
        buttonCancelReply.addTarget(nil, action: #selector(self.deleteReplyView), for: .touchUpInside)
        buttonCancelReply.backgroundColor = .clear
        buttonCancelReply.tintColor = .mainColor
        
        if (attachment_flag == "1" || attachment_flag == "2" || image_chat != "" || video_chat != "") {
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(thumb_chat)
                let image : UIImage? =  {
                    if let img = Nexilis.imageCache.object(forKey: thumb_chat as NSString) {
                        return img
                    }
                    else if let img = UIImage(contentsOfFile: thumbURL.path)?.resize(target: CGSize(width: 500, height: 500)) {
                        Nexilis.imageCache.setObject(img, forKey: thumb_chat as NSString)
                        return img
                    }
                    return nil
                }()
                //                let image = UIGraphicsRenderer.renderImageAt(url: thumbURL as NSURL, size: CGSize(width: 250, height: 250))
                let imageThumb = UIImageView(image: image)
                self.containerPreviewReply.addSubview(imageThumb)
                imageThumb.layer.cornerRadius = 2.0
                imageThumb.clipsToBounds = true
                imageThumb.translatesAutoresizingMaskIntoConstraints = false
                imageThumb.trailingAnchor.constraint(equalTo: buttonCancelReply.leadingAnchor, constant: -10).isActive = true
                imageThumb.centerYAnchor.constraint(equalTo: self.containerPreviewReply.centerYAnchor).isActive = true
                imageThumb.widthAnchor.constraint(equalToConstant: 30).isActive = true
                imageThumb.heightAnchor.constraint(equalToConstant: 30).isActive = true
                
                if (attachment_flag == "2") {
                    let imagePlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
                    imageThumb.addSubview(imagePlay)
                    imagePlay.clipsToBounds = true
                    imagePlay.translatesAutoresizingMaskIntoConstraints = false
                    imagePlay.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                    imagePlay.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                    imagePlay.widthAnchor.constraint(equalToConstant: 10).isActive = true
                    imagePlay.heightAnchor.constraint(equalToConstant: 10).isActive = true
                    imagePlay.tintColor = .white
                }
            }
        }
        if (attachment_flag == "11") {
            let imageSticker = UIImageView(image: UIImage(named: (message_text.components(separatedBy: "/")[1]), in: Bundle.resourceBundle(for: Nexilis.self), with: nil))
            self.containerPreviewReply.addSubview(imageSticker)
            imageSticker.layer.cornerRadius = 2.0
            imageSticker.clipsToBounds = true
            imageSticker.translatesAutoresizingMaskIntoConstraints = false
            imageSticker.trailingAnchor.constraint(equalTo: buttonCancelReply.leadingAnchor, constant: -10).isActive = true
            imageSticker.centerYAnchor.constraint(equalTo: self.containerPreviewReply.centerYAnchor).isActive = true
            imageSticker.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageSticker.heightAnchor.constraint(equalToConstant: 30).isActive = true
        }
    }
    
    func scrollToFirstSearchMessage(indexScroll: Int = 1) {
        if textSearch.count < 2 {
            return
        }
        var lastIndex = 0
        let messageTextForSearch: [[String: Any?]] = self.dataMessages.reversed()
        for idx in 0..<messageTextForSearch.count {
            if (messageTextForSearch[idx]["message_text"]  as? String ?? "").lowercased().contains(textSearch) {
                lastIndex += 1
                if lastIndex < indexScroll {
                    continue
                }
                lastScrollIdxSearch = lastIndex
                let section = self.dataDates.firstIndex(of: messageTextForSearch[idx]["chat_date"]  as? String ?? "")
                if section == nil {
                    return
                }
                let row = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataDates[section!]}).firstIndex(where: { $0["message_id"]  as? String ?? "" == messageTextForSearch[idx]["message_id"]  as? String ?? ""})
                if row == nil {
                    return
                }
                let indexPath = IndexPath(row: row!, section: section!)
                self.tableChatView.scrollToRow(at: indexPath, at: .middle, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let cell = self.tableChatView.cellForRow(at: indexPath) {
                        let containerMessage = cell.contentView.subviews[1]
                        let idMe = User.getMyPin() as String?
                        if (messageTextForSearch[idx]["f_pin"] as? String == idMe) {
                            containerMessage.backgroundColor = .blueBubbleColor.withAlphaComponent(0.3)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if (messageTextForSearch[idx]["attachment_flag"] as? String == "11") {
                                    containerMessage.backgroundColor = .clear
                                } else {
                                    containerMessage.backgroundColor = .blueBubbleColor
                                }
                            }
                        } else {
                            containerMessage.backgroundColor = .whiteBubbleColor.withAlphaComponent(0.3)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if (messageTextForSearch[idx]["attachment_flag"] as? String == "11") {
                                    containerMessage.backgroundColor = .clear
                                } else {
                                    containerMessage.backgroundColor = .whiteBubbleColor
                                }
                            }
                        }
                    }
                }
                titleSearchMatches.isHidden = false
                if countMatchesSearch != 0 {
                    if countMatchesSearch > 1 {
                        titleSearchMatches.text = "\(lastScrollIdxSearch) " + "of".localized() + " \(countMatchesSearch) " + "matches".localized()
                    } else {
                        titleSearchMatches.text = "\(countMatchesSearch) " + "matches".localized()
                    }
                } else {
                    titleSearchMatches.text = "Not found".localized()
                }
                if lastScrollIdxSearch == countMatchesSearch || countMatchesSearch == 0 {
                    buttonUp.isEnabled = false
                    buttonUp.tintColor = .gray
                } else {
                    buttonUp.isEnabled = true
                    buttonUp.tintColor = .mainColor
                }
                if countMatchesSearch == 0 || lastScrollIdxSearch == 1 || countMatchesSearch == 1 {
                    buttonDown.isEnabled = false
                    buttonDown.tintColor = .gray
                } else {
                    buttonDown.isEnabled = true
                    buttonDown.tintColor = .mainColor
                }
                break
            }
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let indexPath = tableChatView.indexPathsForVisibleRows?.first
        if indexPath != nil {
            let headerRect = tableChatView.rectForHeader(inSection: indexPath!.section)
            let isPinned = headerRect.origin.y <= scrollView.contentOffset.y
            if listViewOnSection.count != 0 && listViewOnSection.count - 1 == indexPath!.section && indexPath!.row > 0 {
                let sect = listViewOnSection.count - 1 < currentIndexpath!.section ? listViewOnSection.count - 1 : currentIndexpath!.section
                let headerView = listViewOnSection[sect]
                headerView.isHidden = true
            }
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            let indexPath = tableChatView.indexPathsForVisibleRows?.first
            if indexPath != nil {
                let headerRect = tableChatView.rectForHeader(inSection: indexPath!.section)
                let isPinned = headerRect.origin.y <= scrollView.contentOffset.y
                if listViewOnSection.count != 0 && listViewOnSection.count - 1 == indexPath!.section && isPinned {
                    let sect = listViewOnSection.count - 1 < currentIndexpath!.section ? listViewOnSection.count - 1 : currentIndexpath!.section
                    let headerView = listViewOnSection[sect]
                    headerView.isHidden = true
                }
            }
        }
    }
}
    
extension EditorGroup: UISearchBarDelegate {
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timerSearch?.invalidate()
        if searchText.count > 1 {
            timerSearch = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {[self] _ in
                textSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                titleSearchMatches.isHidden = true
                countMatchesSearch = Chat.getCountSearchMessage(key: textSearch, pin: (self.dataGroup["group_id"] as? String) ?? "", chatId: (self.dataTopic["chat_id"] as? String) ?? "", isPersonal: false)
                tableChatView.reloadData()
                scrollToFirstSearchMessage()
            })
        }
    }
}
    
