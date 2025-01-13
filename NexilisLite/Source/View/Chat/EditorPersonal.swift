//
//  EditorPersonal.swift
//  Qmera
//
//  Created by Akhmad Al Qindi Irsyam on 31/08/21.
//

import UIKit
import AVKit
import AVFoundation
import QuickLook
import NotificationBannerSwift
import Photos
import nuSDKService
import SwiftLinkPreview

public class EditorPersonal: UIViewController, ImageVideoPickerDelegate, UIGestureRecognizerDelegate {
    @IBOutlet var viewButton: UIView!
    @IBOutlet var constraintViewTextField: NSLayoutConstraint!
    @IBOutlet var buttonVoice: UIButton!
    @IBOutlet var buttonSendImage: UIButton!
    @IBOutlet var buttonSendPhoto: UIButton!
    @IBOutlet var buttonSendSticker: UIButton!
    @IBOutlet var buttonSendFile: UIButton!
    @IBOutlet var textFieldSend: UITextView!
    @IBOutlet var heightTextFieldSend: NSLayoutConstraint!
    @IBOutlet var buttonSendChat: UIButton!
    @IBOutlet var tableChatView: UITableView!
    @IBOutlet var constraintTopTextField: NSLayoutConstraint!
    @IBOutlet var constraintBottomAttachment: NSLayoutConstraint!
    @IBOutlet var viewTextfield: UIView!
    @IBOutlet weak var buttonAckConfidential: UIButton!
    @IBOutlet weak var constraintLeftTextField: NSLayoutConstraint!
    @IBOutlet weak var constraintBottomTableViewWithTextfield: NSLayoutConstraint!
    @IBOutlet weak var viewAttachment: UIStackView!
    public var dataPerson: [String: String?] = [:]
    var dataMessages: [[String: Any?]] = []
    var dataDates: [String] = []
    var users: [User] = []
    public var dataMessageForward: [[String: Any?]]?
    var imageVideoPicker: ImageVideoPicker!
    var documentPicker: DocumentPicker!
    var currentIndexpath: IndexPath?
    var previewItem: NSURL?
    var reffId: String?
    var stickers = [String]()
    public var unique_l_pin = ""
    public var isContactCenter = false
    public var isRequestContactCenter = true
    public var fromNotification = false
    public var onGoingCC = false
    public var fPinContacCenter = ""
    public var complaintId = ""
    var channelContactCenter = ""
    var counter = 0
    var dateStartCC = ""
    var markerCounter: String?
    var buttonScrollToBottom = UIButton()
    let indicatorCounterBSTB = UIView()
    let labelCounter = UILabel()
    var copySession = false
    var forwardSession = false
    var deleteSession = false
    var isSearching = false
    let containerMultpileSelectSession = UIView()
    let containerAction = UIView()
    var removed = false
    var isConfidential = false
    var isAck = false
    let viewSticker = UIView()
    let containerLink = UIView()
    let containerPreviewReply = UIView()
    var bottomAnchorPreviewReply = NSLayoutConstraint()
    var blocking = ""
    var timeoutCC = Timer()
    var nowSelectedCategoryCC = ""
    var showToastTwiceClick = false
    var showToast30s = false
    var allowTyping = true
    var hapticSwipeLeft = false
    var listTimerCredential: [String: Int] = [:]
    var timerCredential: [String: Timer] = [:]
    let contactChatNav = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactChatNav") as! UINavigationController
    var searchBar: UISearchBar!
    var constraintBottomContainerMultpileSelectSession = NSLayoutConstraint()
    var titleSearchMatches: UILabel!
    var textSearch = ""
    var countMatchesSearch = 0
    var lastScrollIdxSearch = 0
    var buttonUp: UIButton!
    var buttonDown: UIButton!
    var multipleOffsetUp = 1
    var lastOffsetDown = 1
    var gettingDataMessage = true
    var showingLink = ""
    var isAlwaysHideLinkPreview = false
    var timerCheckLink: Timer?
    var timerLongPressLink: Timer?
    var timerFakeProgress: Timer?
    var showMenuContext = false
    var touchedSubview = UIView()
    var listViewOnSection: [UIView] = []
    var fromVCAC = false
    var serviceIdCC = ""
    var isDirectCC = false
    var fakeProgMultip = 0
    let maxFakeProgMultip = 2
    var groupImages: [String:[ImageGrouping]] = [:]
    var titleText: String!
    var lastY: CGFloat = 0
    var isEditAction: Bool = false
    
    public override func viewDidDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            for timer in self.timerCredential.values {
                timer.invalidate()
            }
            self.timeoutCC.invalidate()
            SecureUserDefaults.shared.removeValue(forKey: "inEditorPersonal")
            NotificationCenter.default.removeObserver(self)
            super.viewDidDisappear(true)
            self.removeFromParent()
            self.dismiss(animated: true, completion: nil)
            if !isContactCenter {
                let l_pin = self.dataPerson["f_pin"]!!
                SecureUserDefaults.shared.set("\(textFieldSend.textColor != UIColor.lightGray ? textFieldSend.text! : ""),\(reffId ?? "")", forKey: "saved_\(l_pin)")
            }
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
        navigationController?.navigationBar.barStyle = .black
        if self.navigationController?.isNavigationBarHidden ?? false {
            self.navigationController?.setNavigationBarHidden(false, animated: false)
        }
        updateProfile()
        gettingDataMessage = false
        let indexPath = tableChatView.indexPathsForVisibleRows?.first
        if indexPath != nil {
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
        Utils.addBackground(view: contactChatNav.view)
        
        viewButton.layer.shadowColor = self.traitCollection.userInterfaceStyle == .dark ? UIColor.white.cgColor : UIColor.gray.cgColor
        viewButton.layer.shadowOpacity = 1
        viewButton.layer.shadowOffset = .zero
        viewButton.layer.shadowRadius = 3
        viewButton.addTopBorder(with: UIColor.lightGray, andWidth: 1.0)
        
//        buttonVoice.setImage(resizeImage(image: UIImage(named: "Voice-Record", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)), for: .normal)
        buttonSendImage.setImage(resizeImage(image: UIImage(named: "Send-Image", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withTintColor(self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor), for: .normal)
        buttonSendPhoto.setImage(resizeImage(image: UIImage(named: "Camera", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withTintColor(self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor), for: .normal)
        buttonSendSticker.setImage(resizeImage(image: UIImage(named: "Sticker---Emoji", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withTintColor(self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor), for: .normal)
        buttonSendFile.setImage(resizeImage(image: UIImage(named: "File---Documents", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withTintColor(self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor), for: .normal)
        
        buttonSendChat.setImage(resizeImage(image: self.traitCollection.userInterfaceStyle == .dark ? UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(.blackDarkMode) : UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal), for: .normal)
        
        buttonSendChat.circle()
        buttonSendChat.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        buttonSendChat.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
        if isContactCenter {
            buttonAckConfidential.isHidden = true
            constraintLeftTextField.constant = 20
        } else {
            buttonAckConfidential.circle()
            buttonAckConfidential.addTarget(self, action: #selector(showChooserACKConfidential), for: .touchUpInside)
            buttonAckConfidential.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
            buttonAckConfidential.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
        }
        textFieldSend.layer.cornerRadius = textFieldSend.maxCornerRadius()
        textFieldSend.layer.borderWidth = 1.0
        textFieldSend.text = "Send message".localized()
        textFieldSend.textColor = UIColor.lightGray
        textFieldSend.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        textFieldSend.textContainerInset = UIEdgeInsets(top: 12, left: 20, bottom: 11, right: 40)
        textFieldSend.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        textFieldSend.font = UIFont.systemFont(ofSize: 12)
        textFieldSend.delegate = self
        textFieldSend.allowsEditingTextAttributes = true
        
        navigationItem.rightBarButtonItem?.tintColor = UIColor.secondaryColor
        
        imageVideoPicker = ImageVideoPicker(presentationController: self, delegate: self)
        documentPicker = DocumentPicker(presentationController: self, delegate: self)
        
        let fm = FileManager.default
        let path = Bundle.resourceBundle(for: Nexilis.self).resourcePath! //resourcesMediaBundle
        let items = try! fm.contentsOfDirectory(atPath: path)
        
        for item in items {
            if item.hasPrefix("sticker") {
                stickers.append(item)
            }
        }
        
        tableChatView.register(UITableViewCell.self, forCellReuseIdentifier: "cellEditorPersonal")
        
        loadData()
        setRightButtonItem()
        
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(onReceiveMessage(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerReceiveChat), object: nil)
        center.addObserver(self, selector: #selector(onStatusChat(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerStatusChat), object: nil)
        center.addObserver(self, selector: #selector(onUploadChat(notification:)), name: NSNotification.Name(rawValue: "onUploadChat"), object: nil)
        center.addObserver(self, selector: #selector(onUnfriend(notification:)), name: NSNotification.Name(rawValue: "onUpdatePersonInfo"), object: nil)
        center.addObserver(self, selector: #selector(onTyping(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerTypingChat), object: nil)
        center.addObserver(self, selector: #selector(onFailedSendMessage(notification:)), name: NSNotification.Name(rawValue: Nexilis.failedSendMessage), object: nil)
        
        if dataMessageForward != nil {
            for i in 0..<dataMessageForward!.count {
                sendChat(message_scope_id: "3", status: "2", message_text: dataMessageForward![i]["message_text"] as! String, credential: "0", attachment_flag: dataMessageForward![i]["attachment_flag"] as! String, ex_blog_id: "", message_large_text: "", ex_format: "", image_id: dataMessageForward![i]["image_id"] as! String, audio_id: dataMessageForward![i]["audio_id"] as! String, video_id: dataMessageForward![i]["video_id"] as! String, file_id: dataMessageForward![i]["file_id"] as! String, thumb_id: dataMessageForward![i]["thumb_id"] as! String, reff_id: "", read_receipts: dataMessageForward![i]["read_receipts"] as! String, chat_id: "", is_call_center: "0", call_center_id: "", viewController: self)
            }
            dataMessageForward = nil
        }
        
        if isContactCenter && !isRequestContactCenter && !onGoingCC {
            var companyName = ""
            Database.shared.database?.inTransaction({ fmdb, rollback in
                do {
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT first_name, last_name FROM BUDDY where official_account = '1'"), cursor.next() {
                        companyName = cursor.string(forColumnIndex: 0)! + " " + cursor.string(forColumnIndex: 1)!
                        companyName = companyName.trimmingCharacters(in: .whitespaces)
                        cursor.close()
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
            self.dateStartCC = "\(Date().currentTimeMillis())"
            let myName = User.getData(pin: User.getMyPin() as String?)
            sendChat(message_text: "Hi \(dataPerson["name"]!!), thank you for contacting \(companyName). My name is \(myName!.fullName.trimmingCharacters(in: .whitespaces)), how can I help you?".localized(), ex_format: "1", is_call_center: "1", call_center_id: complaintId, viewController: self, isAutoSendCC: true)
            if channelContactCenter == "1" {
                if let pin = dataPerson["f_pin"] {
                    let controller = QmeraAudioViewController()
                    controller.user = User.getData(pin: pin)
                    controller.isOutgoing = true
                    controller.modalPresentationStyle = .overCurrentContext
                    present(controller, animated: true, completion: nil)
                }
            } else if channelContactCenter == "2" {
                let videoVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "videoVCQmera") as! QmeraVideoViewController
                videoVC.dataPerson.append(dataPerson)
                self.show(videoVC, sender: nil)
            }
        }
        if isDirectCC {
            directCC()
        }
//        else if isContactCenter {
//            let buttonId = UIButton()
//            if channelContactCenter == "0" {
//                buttonId.tag = 0
//                ccAction(sender: buttonId)
//            } else if channelContactCenter == "1" {
//                buttonId.tag = 1
//                ccAction(sender: buttonId)
//            } else if channelContactCenter == "2" {
//                buttonId.tag = 2
//                ccAction(sender: buttonId)
//            }
//        }
    }
    
    public func afterUnfriend() {
        DispatchQueue.main.async {
            for timer in self.timerCredential.values {
                timer.invalidate()
            }
            self.timeoutCC.invalidate()
            SecureUserDefaults.shared.removeValue(forKey: "inEditorPersonal")
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    private func setRightButtonItem() {
        navigationItem.rightBarButtonItems = nil
        let actionDelete = UIAction(title: "Delete Conversation".localized(), handler: {(_) in
            if !self.isContactCenter {
                let alert = LibAlertController(title: "", message: "Are you sure to delete all message in this conversation?".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel".localized(), style: UIAlertAction.Style.default, handler: nil))
                alert.addAction(UIAlertAction(title: "Delete".localized(), style: .destructive, handler: {(_) in
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "(f_pin='\(self.dataPerson["f_pin"]!!)' or l_pin='\(self.dataPerson["f_pin"]!!)') and (message_scope_id='3' or message_scope_id='18') and is_call_center = 0")
                            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "l_pin='\(self.dataPerson["f_pin"]!!)'")
                            let l_pin = self.dataPerson["f_pin"]!!
                            SecureUserDefaults.shared.removeValue(forKey: "saved_\(l_pin)")
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
            }
        })
        let actionSearch = UIAction(title: "Search".localized(), handler: {(_) in
            self.isSearching = true
            if self.reffId != nil {
                self.deleteReplyView()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
                cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
                if self.dataPerson["f_pin"] != "-999" && !self.isContactCenter {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                if self.isContactCenter || self.fromNotification {
                    self.navigationItem.leftBarButtonItem = nil
                }
                self.changeAppBar()
                self.addMultipleSelectSession()
            }
        })
        let actionUnblock = UIAction(title: "Unblock".localized(), handler: {(_) in
            if !self.isContactCenter {
                DispatchQueue.global().async {
                    if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getUnBlock(l_pin: self.dataPerson["f_pin"]!!)) {
                        if !response.isOk() {
                            DispatchQueue.main.async {
                                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Unable to complete action".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                                banner.show()
                            }
                        } else {
                            DispatchQueue.main.async { [self] in
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: [
                                            "ex_block" : "0"
                                        ], _where: "f_pin = '\(self.dataPerson["f_pin"]!!)'")
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                                containerAction.subviews.forEach({ $0.removeFromSuperview() })
                                containerAction.removeFromSuperview()
                                setRightButtonItem()
                                changeAppBar()
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        }
                    }
                }
            }
        })
        let actionBlock = UIAction(title: "Block".localized(), handler: {(_) in
            if !self.isContactCenter {
                DispatchQueue.global().async {
                    if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getBlock(l_pin: self.dataPerson["f_pin"]!!)) {
                        if !response.isOk() {
                            DispatchQueue.main.async {
                                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Unable to complete action".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                                banner.show()
                            }
                        } else {
                            DispatchQueue.main.async { [self] in
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: [
                                            "ex_block" : "1"
                                        ], _where: "f_pin = '\(self.dataPerson["f_pin"]!!)'")
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                                setRightButtonItem()
                                changeAppBar()
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        }
                    }
                }
            }
        })
        var menu = UIMenu(title: "", children: [
            actionSearch,
            actionDelete
        ])
        let exblock = User.getDataCanNil(pin: self.dataPerson["f_pin"]!!)?.ex_block
        blocking = exblock == nil ? "0" : exblock!.isEmpty ? "0" : exblock!
        if blocking == "1" && self.dataPerson["f_pin"]!! != "-999" {
            menu = UIMenu(title: "", children: [
                actionSearch,
                actionUnblock,
                actionDelete
            ])
            blockedView(blocked: "1")
        } else if blocking == "0" {
            if self.dataPerson["f_pin"]!! != "-999" && complaintId.isEmpty {
                menu = UIMenu(title: "", children: [
                    actionSearch,
                    actionBlock,
                    actionDelete
                ])
            } else if  !complaintId.isEmpty{
                menu = UIMenu(title: "", children: [
                    actionSearch
                ])
            }
                else {
                menu = UIMenu(title: "", children: [
                    actionSearch,
                    actionDelete
                ])
            }
            if containerAction.isDescendant(of: self.view) {
                containerAction.subviews.forEach({ $0.removeFromSuperview() })
                containerAction.removeFromSuperview()
            }
        } else {
            blockedView(blocked: "-1")
            changeAppBar()
        }
        
        let moreIcon = UIBarButtonItem(image: UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), menu: menu)
        let buttonAudioCall = UIBarButtonItem(image: UIImage(systemName: "phone", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), style: .plain, target: self, action: #selector(audioVideoCall(sender:)))
//        let buttonSearch = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), style: .plain, target: self, action: #selector(audioVideoCall(sender:)))
        buttonAudioCall.tag = 0
        let buttonVideoCall = UIBarButtonItem(image: UIImage(systemName: "video", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), style: .plain, target: self, action: #selector(audioVideoCall(sender:)))
        buttonVideoCall.tag = 1
        let buttonAddRoom = UIBarButtonItem(image: UIImage(systemName: "plus.message", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), style: .plain, target: self, action: #selector(addRoom(sender:)))
        if dataPerson["f_pin"] != "-999" && !isContactCenter && blocking == "0" {
            navigationItem.rightBarButtonItems = [moreIcon,buttonAudioCall,buttonVideoCall]
        } else if !isContactCenter {
            navigationItem.rightBarButtonItem = moreIcon
        } else if !complaintId.isEmpty { //!complaintId.isEmpty
            navigationItem.rightBarButtonItems = [moreIcon,buttonAddRoom]
        }
    }
    
    func loadData() {
        if (unique_l_pin != "" || isContactCenter) {
            getDataProfile(fPin: unique_l_pin)
            if isContactCenter && !isRequestContactCenter && users.count == 0 {
                if !unique_l_pin.isEmpty {
                    users.append(User.getData(pin: unique_l_pin) ?? User(pin: ""))
                }
            }
        }
        
        if onGoingCC {
            SecureUserDefaults.shared.set(self.fPinContacCenter, forKey: "inEditorPersonal")
        } else {
            SecureUserDefaults.shared.set(dataPerson["f_pin"]!, forKey: "inEditorPersonal")
        }
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [dataPerson["f_pin"]!!])
        
        if isContactCenter || fromNotification {
            let imageButton = UIImageView(frame: CGRect(x: -16, y: 0, width: 20, height: 44))
            imageButton.image = UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default))?.withTintColor(.white)
            imageButton.contentMode = .left
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapExit))
            imageButton.isUserInteractionEnabled = true
            imageButton.addGestureRecognizer(tapGestureRecognizer)
            let leftItem = UIBarButtonItem(customView: imageButton)
            self.navigationItem.leftBarButtonItem = leftItem
        }
        
        if dataPerson["f_pin"] == "-999" {
            chatbot()
        }
        
        let exblock = User.getData(pin: self.dataPerson["f_pin"]!!)?.ex_block
        blocking = exblock == nil ? "0" : exblock!.isEmpty ? "0" : exblock!
        
        changeAppBar()
        getData()
        
        tableChatView.alpha = 0
        tableChatView.delegate = self
        tableChatView.dataSource = self
        tableChatView.keyboardDismissMode = .interactive
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableChatView.addGestureRecognizer(tapGesture)
        
        if !isContactCenter {
            getCounter()
            if counter > 0 && dataMessages.count >= counter {
                markerCounter = dataMessages[dataMessages.count - counter]["message_id"] as? String
            }
            
            tableChatView.alpha = 0
            if counter != 0 && dataMessages.count >= counter {
                if dataMessages.firstIndex(where: {$0["message_id"] as? String == markerCounter} ) != 0 {
                    DispatchQueue.main.async {
                        let data = self.dataMessages.filter({ $0["message_id"] as? String == self.markerCounter })
                        let section = self.dataDates.firstIndex(of: data[0]["chat_date"] as! String)
                        let row = self.dataMessages.filter({$0["chat_date"] as! String == data[0]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.markerCounter})
                        self.tableChatView.scrollToRow(at: IndexPath(row: row!, section: section!), at: .bottom, animated: false)
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
                                    sendReadMessageStatus(chat_id: "", f_pin: dataPerson["f_pin"]!!, message_scope_id: "3", message_id: dataMessages[i]["message_id"] as! String)
                                }
                            }
                            counter = 0
                            updateCounter(counter: counter)
                        }
                    }
                }
            } else {
                let l_pin = self.dataPerson["f_pin"]
                if let dataSaved: String = SecureUserDefaults.shared.value(forKey: "saved_\(l_pin)") {
                    let last_m = dataSaved.components(separatedBy: ",")[0]
                    let last_r = dataSaved.components(separatedBy: ",")[1]
                    if !last_m.isEmpty {
                        textFieldSend.text = last_m
                        textFieldSend.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black
                    }
                    
                    if !last_r.isEmpty {
                        handleReply(indexPath: IndexPath(row: 0, section: 0), reffId: last_r)
                    }
                }
                tableChatView.scrollToBottom(isAnimated: false)
            }
        } else if isContactCenter && onGoingCC {
            let idMe = User.getMyPin() as String?
            for i in 0..<dataMessages.count {
                if dataMessages[i]["f_pin"] as? String != idMe {
                    sendReadMessageStatus(chat_id: "", f_pin: dataPerson["f_pin"]!!, message_scope_id: "3", message_id: dataMessages[i]["message_id"] as! String)
                }
            }
            tableChatView.scrollToBottom(isAnimated: false)
        } else {
            tableChatView.scrollToBottom(isAnimated: false)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
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
                        let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                        let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
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
    }
    
    private func chatbot() {
        let containerChatbot = UIView()
        self.view.addSubview(containerChatbot)
        containerChatbot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerChatbot.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            containerChatbot.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            containerChatbot.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            containerChatbot.heightAnchor.constraint(equalToConstant: 120)
        ])
        containerChatbot.backgroundColor = .secondaryColor.withAlphaComponent(0.8)
        
        let labelChatbot = UILabel()
        containerChatbot.addSubview(labelChatbot)
        labelChatbot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelChatbot.centerYAnchor.constraint(equalTo: containerChatbot.centerYAnchor),
            labelChatbot.centerXAnchor.constraint(equalTo: containerChatbot.centerXAnchor),
        ])
        labelChatbot.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        labelChatbot.font = UIFont.systemFont(ofSize: 12).bold
        labelChatbot.text = "Interactive chatbot. Coming soon".localized()
    }
    
    private func changeAppBar() {
        let viewAppBar = UIView()
        viewAppBar.frame.size = CGSize(width: self.view.frame.size.width, height: 44)
        
        if !isSearching {
            let imageProfile = UIImageView(frame: CGRect(x: 0, y: 7, width: 30, height: 30))
            imageProfile.circle()
            imageProfile.clipsToBounds = true
            let pictureImage = dataPerson["picture"]!
            var count = 0
            if isContactCenter {
                if fPinContacCenter.isEmpty && isRequestContactCenter {
                    getImage(name: dataPerson["picture"]!!, placeholderImage: UIImage(systemName: "person.circle.fill")!) { result, isDownloaded, image in
                        imageProfile.image = image
                    }
                    viewAppBar.addSubview(imageProfile)
                } else {
                    if users.count == 1 {
                        viewAppBar.addSubview(imageProfile)
                        getImage(name: users[0].thumb, placeholderImage: UIImage(systemName: "person.circle.fill")!) { result, isDownloaded, image in
                            imageProfile.image = image
                            imageProfile.contentMode = .scaleAspectFit
                        }
                    } else {
                        for user in users {
                            if count == 3 {
                                count += 1
                                continue
                            }
                            if count == 0 {
                                let pictures = UIImageView(frame: CGRect(x: 0, y: 7, width: 30, height: 30))
                                pictures.circle()
                                pictures.clipsToBounds = true
                                viewAppBar.addSubview(pictures)
                                getImage(name: user.thumb, placeholderImage: UIImage(systemName: "person.circle.fill")!) { result, isDownloaded, image in
                                    pictures.image = image
                                    pictures.contentMode = .scaleAspectFit
                                }
                            } else {
                                let pictures = UIImageView(frame: CGRect(x: count * 20 , y: 7, width: 30, height: 30))
                                pictures.circle()
                                pictures.clipsToBounds = true
                                viewAppBar.addSubview(pictures)
                                getImage(name: user.thumb, placeholderImage: UIImage(systemName: "person.circle.fill")!) { result, isDownloaded, image in
                                    pictures.image = image
                                    pictures.contentMode = .scaleAspectFit
                                }
                            }
                            count += 1
                        }
                    }
                }
            } else if dataPerson["f_pin"]!! == "-999" {
                viewAppBar.addSubview(imageProfile)
                if !Utils.getIconDock().isEmpty {
                    let dataImage = try? Data(contentsOf: URL(string: Utils.getUrlDock()!)!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                    if dataImage != nil {
                        imageProfile.image = UIImage(data: dataImage!)
                    }
                } else {
                    imageProfile.image = UIImage(named: "pb_button", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                }
                imageProfile.contentMode = .scaleAspectFit
            }
            else if (pictureImage != "" && pictureImage != nil) {
                viewAppBar.addSubview(imageProfile)
                imageProfile.setImage(name: pictureImage!)
                imageProfile.contentMode = .scaleAspectFill
            } else {
                viewAppBar.addSubview(imageProfile)
                imageProfile.image = UIImage(systemName: "person")
                imageProfile.contentMode = .scaleAspectFit
                imageProfile.backgroundColor = .lightGray
            }
            
            var titleNavigation = UILabel(frame: CGRect(x: 35, y: 0, width: viewAppBar.frame.size.width - 250, height: 44))
            if blocking == "-1" || blocking == "1" {
                titleNavigation = UILabel(frame: CGRect(x: 35, y: 0, width: viewAppBar.frame.size.width - 150, height: 44))
            } else if isContactCenter {
                titleNavigation = UILabel(frame: CGRect(x: 35, y: 0, width: viewAppBar.frame.size.width - 150, height: 44))
                if users.count > 0 {
                    titleNavigation = UILabel(frame: CGRect(x: 35 * (CGFloat(users.count)) - (CGFloat((users.count - 1) * 15)), y: 0, width: viewAppBar.frame.size.width - 150 - (35 * (CGFloat(users.count - 1)) - (CGFloat((users.count - 1) * 15))), height: 44))
                }
            }
            viewAppBar.addSubview(titleNavigation)
            if ((User.isOfficial(official_account: (dataPerson["isOfficial"] ?? "")!) || User.isOfficialRegular(official_account: (dataPerson["isOfficial"] ?? "")!)) && !isContactCenter) || ((User.isOfficial(official_account: (dataPerson["isOfficial"] ?? "")!) || User.isOfficialRegular(official_account: (dataPerson["isOfficial"] ?? "")!)) && fPinContacCenter.isEmpty) {
                var name = dataPerson["name"]!!
                if (isContactCenter) {
                    name = name + " " + "Contact Center".localized()
                    titleNavigation.text = name
                } else {
                    titleNavigation.set(image: UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(name)", size: 15, y: -4)
                }
            } else if User.isVerified(official_account: (dataPerson["isOfficial"] ?? "")!) && !isContactCenter {
                let name = dataPerson["name"]!!
                titleNavigation.set(image: UIImage(named: "ic_verified", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(name)", size: 15, y: -4)
            } else if User.isInternal(userType: (dataPerson["user_type"] ?? "")!) && !isContactCenter {
                let name = dataPerson["name"]!!
                titleNavigation.set(image: UIImage(named: "ic_internal", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(name)", size: 15, y: -4)
            } else {
                if !isContactCenter {
                    titleNavigation.text = dataPerson["name"] as? String
                } else {
                    if users.count == 1 {
                        titleNavigation.text = users[0].fullName
                    } else {
                        var stringName = ""
                        for user in users {
                            if stringName.isEmpty {
                                stringName = user.fullName
                            } else {
                                stringName += ", \(user.fullName)"
                            }
                        }
                        titleNavigation.text = stringName
                    }
                }
            }
            titleNavigation.textColor = .white
            titleNavigation.font = UIFont.systemFont(ofSize: 12).bold
            navigationItem.titleView = viewAppBar
            titleText = titleNavigation.text
        } else {
            searchBar = UISearchBar()
            searchBar.autocapitalizationType = .none
            searchBar.delegate = self
            searchBar.searchTextField.tintColor = .mainColor
            searchBar.searchTextField.textColor = .mainColor
            searchBar.showsCancelButton = false
//            searchBar.setMagnifyingGlassColorTo(color: .white)
//            searchBar.updateHeight(height: 36, radius: 18)
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
    
    private func getDataProfile(fPin: String) {
        var query = "SELECT f_pin, first_name || ' ' || last_name, official_account, image_id, device_id, offline_mode, user_type FROM BUDDY where f_pin = '\(fPin)'"
        if (isContactCenter && isRequestContactCenter) {
            query = "SELECT group_id, f_name, official, image_id FROM GROUPZ where group_type = 1 AND official = 1"
        }
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    if cursorData.next() {
                        dataPerson["f_pin"] = cursorData.string(forColumnIndex: 0)
                        dataPerson["name"] = cursorData.string(forColumnIndex: 1)?.trimmingCharacters(in: .whitespaces)
                        dataPerson["picture"] = cursorData.string(forColumnIndex: 3)
                        dataPerson["isOfficial"] = cursorData.string(forColumnIndex: 2)
                        if isContactCenter && isRequestContactCenter {
                            dataPerson["user_type"] = "0"
                        } else {
                            dataPerson["user_type"] = cursorData.string(forColumnIndex: 6)
                        }
                    } else {
                        dataPerson["f_pin"] = "-999"
                        dataPerson["name"] = "Bot"
                        dataPerson["picture"] = ""
                        dataPerson["isOfficial"] = ""
                        dataPerson["deviceId"] = ""
                        dataPerson["isOffline"] = "0"
                        dataPerson["user_type"] = "0"
                    }
                    cursorData.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    private func addDataMessage() {
        multipleOffsetUp += 1
        let queryCount = "SELECT COUNT(*) FROM MESSAGE where (f_pin='\(dataPerson["f_pin"]!!)' or l_pin='\(dataPerson["f_pin"]!!)') AND (message_scope_id = '3' OR message_scope_id = '18') AND is_call_center = 0"
        let query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared, blog_id, credential, is_call_center, call_center_id, opposite_pin, last_edited FROM MESSAGE where (f_pin='\(dataPerson["f_pin"]!!)' or l_pin='\(dataPerson["f_pin"]!!)') AND (message_scope_id = '3' OR message_scope_id = '18') AND is_call_center = 0 order by server_date asc LIMIT CASE WHEN (\(queryCount))-\(dataMessages.count)>=20 THEN 20*\(multipleOffsetUp-1) ELSE (\(queryCount))-\(dataMessages.count) END OFFSET CASE WHEN (\(queryCount))>=\(20*multipleOffsetUp) THEN (\(queryCount))-\(20*multipleOffsetUp) ELSE 0 END"
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    var tempData: [[String: Any?]] = []
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
                        row["blog_id"] = cursorData.string(forColumnIndex: 18)
                        row["credential"] = cursorData.string(forColumnIndex: 19)
                        row[TypeDataMessage.is_call_center] = cursorData.string(forColumnIndex: 20)
                        row[TypeDataMessage.call_center_id] = cursorData.string(forColumnIndex: 21)
                        row[TypeDataMessage.opposite_pin] = cursorData.string(forColumnIndex: 22)
                        row[TypeDataMessage.last_edit] = cursorData.longLongInt(forColumnIndex: 23)
                        if let cursorStatus = Database.shared.getRecords(fmdb: fmdb, query: "SELECT status FROM MESSAGE_STATUS WHERE message_id='\(row["message_id"] as! String)'") {
                            while cursorStatus.next() {
                                row["status"] = cursorStatus.string(forColumnIndex: 0)
                            }
                            cursorStatus.close()
                        }
                        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                        if let dirPath = paths.first {
                            let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["video_id"] as! String)
                            let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["file_id"] as! String)
                            if ((row["video_id"] as! String) != "") {
                                if FileManager.default.fileExists(atPath: videoURL.path) || FileEncryption.shared.isSecureExists(filename: videoURL.lastPathComponent){
                                    row["progress"] = 100.0
                                } else {
                                    row["progress"] = 0.0
                                }
                            } else {
                                if FileManager.default.fileExists(atPath: fileURL.path) || FileEncryption.shared.isSecureExists(filename: fileURL.lastPathComponent){
                                    row["progress"] = 100.0
                                } else {
                                    row["progress"] = 0.0
                                }
                            }
                        }
                        row["chat_date"] = chatDate(stringDate: row["server_date"] as! String)
                        row["isSelected"] = false
                        if row["credential"] != nil && row["credential"] as! String == "1" {
                            let idMe = User.getMyPin()!
                            if row["f_pin"] as! String == idMe {
                                let second = getSecondsDifferenceFromTwoDates(start: Date.init(milliseconds: Int64(row["server_date"] as! String)!), end: Date())
                                if second > 60 {
                                    listTimerCredential[row["message_id"] as! String] = 0
                                    row["lock"] = "2"
                                    row["reff_id"] = ""
                                    DispatchQueue.global().async {
                                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                            do {
                                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                                    "lock" : "2"
                                                ], _where: "message_id = '\(row["message_id"] as! String)'")
                                            } catch {
                                                rollback.pointee = true
                                                print("Access database error: \(error.localizedDescription)")
                                            }
                                        })
                                    }
                                } else {
                                    let second = 60 - second
                                    listTimerCredential[row["message_id"] as! String] = second
                                }
                            } else {
                                let hasMessageId: String? = SecureUserDefaults.shared.value(forKey: row["message_id"] as! String) ?? nil
                                if hasMessageId != nil {
                                    let second = getSecondsDifferenceFromTwoDates(start: Date.init(milliseconds: Int64(hasMessageId!)!), end: Date())
                                    if second > 60 {
                                        listTimerCredential[row["message_id"] as! String] = 0
                                        row["lock"] = "2"
                                        row["reff_id"] = ""
                                        DispatchQueue.global().async {
                                            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                                do {
                                                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                                        "lock" : "2"
                                                    ], _where: "message_id = '\(row["message_id"] as! String)'")
                                                } catch {
                                                    rollback.pointee = true
                                                    print("Access database error: \(error.localizedDescription)")
                                                }
                                            })
                                        }
                                    } else {
                                        let second = 60 - second
                                        listTimerCredential[row["message_id"] as! String] = second
                                    }
                                } else {
                                    SecureUserDefaults.shared.set("\(Date().currentTimeMillis())", forKey: row["message_id"] as! String)
                                    listTimerCredential[row["message_id"] as! String] = 60
                                }
                            }
                        }
                        tempData.append(row)
                    }
                    if tempData.count != 0 && (dataMessages.firstIndex(where: { $0["message_id"] as? String == tempData[0]["message_id"] as? String }) == nil) {
                        let lastIndex = tempData.count - 1
                        for i in 0..<tempData.count {
                            tableChatView.beginUpdates()
                            dataMessages.insert(tempData[lastIndex - i], at: 0)
                            if dataMessages.firstIndex(where: { $0["chat_date"] as? String == tempData[lastIndex - i]["chat_date"] as? String }) != nil {
                                tableChatView.insertRows(at: [IndexPath(row: 0, section: currentIndexpath!.section)], with: .top)
                            } else {
                                tableChatView.insertSections(IndexSet(integer: 0), with: .top)
                                tableChatView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
                            }
                            tableChatView.endUpdates()
                        }
                    }
                    cursorData.close()
                    gettingDataMessage = false
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    private func getData() {
//        let queryCount = "SELECT COUNT(*) FROM MESSAGE where (f_pin='\(dataPerson["f_pin"]!!)' or l_pin='\(dataPerson["f_pin"]!!)') AND (message_scope_id = '3' OR message_scope_id = '18') AND is_call_center = 0"
//        var query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared, blog_id, credential FROM MESSAGE where (f_pin='\(dataPerson["f_pin"]!!)' or l_pin='\(dataPerson["f_pin"]!!)') AND (message_scope_id = '3' OR message_scope_id = '18') AND is_call_center = 0 order by server_date asc LIMIT CASE WHEN (\(queryCount))-\(dataMessages.count)>=20 THEN 20 ELSE (\(queryCount))-\(dataMessages.count) END OFFSET CASE WHEN (\(queryCount))>=\(20*multipleOffsetUp) THEN (\(queryCount))-\(20*multipleOffsetUp) ELSE 0 END"
        var query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared, blog_id, credential, is_call_center, call_center_id, opposite_pin, last_edited FROM MESSAGE where (f_pin='\(dataPerson["f_pin"]!!)' or l_pin='\(dataPerson["f_pin"]!!)') AND (message_scope_id = '3' OR message_scope_id = '18') AND is_call_center = 0 order by server_date asc"
        if isContactCenter {
            if complaintId.isEmpty {
                query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared FROM MESSAGE where (f_pin='\(dataPerson["f_pin"]!!)' or l_pin='\(dataPerson["f_pin"]!!)') AND message_scope_id = '5' AND broadcast_flag = 0 AND is_call_center = 1 order by server_date asc"
            } else {
                query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared FROM MESSAGE where message_scope_id = '5' AND broadcast_flag = 0 AND is_call_center = 1 AND call_center_id = '\(complaintId)' order by server_date asc"
            }
            if isRequestContactCenter && !isDirectCC {
                viewButton.isHidden = true
                viewTextfield.isHidden = true
                var row: [String: Any?] = [:]
                row["f_pin"] = nil
                row["message_id"] = ""
                row["chat_date"] = "Today".localized()
                let listStringName: [String] = ["Messaging".localized(), "Secure SMS".localized(), "VoIP Call".localized(), "Email".localized(), "Video Call".localized(), "GSM Call".localized(), "GPT Chatbot".localized(), "WhatsApp"]
                var data : [CategoryCC] = []
                let channels : [String] = ["0", "4", "1", "3", "2", "5", "7", "6"]
                if Utils.getDefaultCC() == "No" {
                    let category = CategoryCC.getDatafromParent(parent: CategoryCC.default_parent)
                    for i in 0..<category.count {
                        data.append(CategoryCC(id: "level0_\(i)", service_id: category[i].service_id, service_name: category[i].service_name, parent: category[i].parent, description: category[i].description, is_tablet: "0"))
                    }
                } else {
                    for i in 0..<listStringName.count {
                        data.append(CategoryCC(id: "level0_\(channels[i])", service_id: "", service_name: listStringName[i], parent: "\(i)", description: "", is_tablet: "0"))
                    }
                    row["attachment_flag"] = "503"
                }
                row["category_cc"] = data
                dataDates.append("Today".localized())
                dataMessages.append(row)
            } else if isDirectCC {
                dataDates.append("Today".localized())
            }
        }
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    var tempImages: [ImageGrouping] = []
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
                        row["blog_id"] = cursorData.string(forColumnIndex: 18)
                        row["credential"] = cursorData.string(forColumnIndex: 19)
                        row[TypeDataMessage.is_call_center] = cursorData.string(forColumnIndex: 20)
                        row[TypeDataMessage.call_center_id] = cursorData.string(forColumnIndex: 21)
                        row[TypeDataMessage.opposite_pin] = cursorData.string(forColumnIndex: 22)
                        row[TypeDataMessage.last_edit] = cursorData.longLongInt(forColumnIndex: 23)
                        if let cursorStatus = Database.shared.getRecords(fmdb: fmdb, query: "SELECT status FROM MESSAGE_STATUS WHERE message_id='\(row["message_id"] as! String)'") {
                            while cursorStatus.next() {
                                row["status"] = cursorStatus.string(forColumnIndex: 0)
                            }
                            cursorStatus.close()
                        }
                        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                        if let dirPath = paths.first {
                            let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["video_id"] as! String)
                            let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["file_id"] as! String)
                            if ((row["video_id"] as! String) != "") {
                                if FileManager.default.fileExists(atPath: videoURL.path) || FileEncryption.shared.isSecureExists(filename: videoURL.lastPathComponent){
                                    row["progress"] = 100.0
                                } else {
                                    row["progress"] = 0.0
                                }
                            } else {
                                if FileManager.default.fileExists(atPath: fileURL.path) || FileEncryption.shared.isSecureExists(filename: fileURL.lastPathComponent){
                                    row["progress"] = 100.0
                                } else {
                                    row["progress"] = 0.0
                                }
                            }
                        }
                        row["chat_date"] = chatDate(stringDate: row["server_date"] as! String)
                        row["isSelected"] = false
                        if row["credential"] != nil && row["credential"] as! String == "1" {
                            let idMe = User.getMyPin()!
                            if row["f_pin"] as! String == idMe {
                                let second = getSecondsDifferenceFromTwoDates(start: Date.init(milliseconds: Int64(row["server_date"] as! String)!), end: Date())
                                if second > 60 {
                                    listTimerCredential[row["message_id"] as! String] = 0
                                    row["lock"] = "2"
                                    row["reff_id"] = ""
                                    DispatchQueue.global().async {
                                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                            do {
                                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                                    "lock" : "2"
                                                ], _where: "message_id = '\(row["message_id"] as! String)'")
                                            } catch {
                                                rollback.pointee = true
                                                print("Access database error: \(error.localizedDescription)")
                                            }
                                        })
                                    }
                                } else {
                                    let second = 60 - second
                                    listTimerCredential[row["message_id"] as! String] = second
                                }
                            } else {
                                let hasMessageId: String? = SecureUserDefaults.shared.value(forKey: row["message_id"] as! String) ?? nil
                                if hasMessageId != nil {
                                    let second = getSecondsDifferenceFromTwoDates(start: Date.init(milliseconds: Int64(hasMessageId!)!), end: Date())
                                    if second > 60 {
                                        listTimerCredential[row["message_id"] as! String] = 0
                                        row["lock"] = "2"
                                        row["reff_id"] = ""
                                        DispatchQueue.global().async {
                                            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                                do {
                                                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                                        "lock" : "2"
                                                    ], _where: "message_id = '\(row["message_id"] as! String)'")
                                                } catch {
                                                    rollback.pointee = true
                                                    print("Access database error: \(error.localizedDescription)")
                                                }
                                            })
                                        }
                                    } else {
                                        let second = 60 - second
                                        listTimerCredential[row["message_id"] as! String] = second
                                    }
                                } else {
                                    SecureUserDefaults.shared.set("\(Date().currentTimeMillis())", forKey: row["message_id"] as! String)
                                    listTimerCredential[row["message_id"] as! String] = 60
                                }
                            }
                        }
                        if (dataMessages.count == 0 || dataMessages.last!["f_pin"] as! String == row["f_pin"] as! String) && tempImages.count <= 30 && row["image_id"] != nil && !(row["image_id"] as! String).isEmpty && (row["message_text"] as! String).isEmpty && (row["reff_id"] as! String).isEmpty && (row["credential"] as! String) != "1" && (row["read_receipts"] as! String) != "8" {
                            if tempImages.count != 0 && getSecondsDifferenceFromTwoDates(start: Date.init(milliseconds: Int64(tempImages.last!.time)!), end: Date.init(milliseconds: Int64(row["server_date"] as! String)!))/60 >= 11 {
                                if tempImages.count >= 4 {
                                    groupImages[tempImages[0].messageId] = tempImages
                                    if let idxTemp = dataMessages.firstIndex(where: { $0["message_id"] as! String == tempImages[0].messageId }) {
                                        for _ in 1..<tempImages.count {
                                            dataMessages.remove(at: idxTemp + 1)
                                        }
                                    }
                                }
                                tempImages.removeAll()
                            }
                            tempImages.append(ImageGrouping(messageId: row["message_id"] as! String, thumbId: row["thumb_id"] as! String, imageId: row["image_id"] as! String, status: row["status"] as! String, time: row["server_date"] as! String, lPin: row["l_pin"] as! String, dataMessage: row, dataPerson: dataPerson, dataGroup: [:], dataTopic: [:]))
                        } else if tempImages.count >= 4 {
                            groupImages[tempImages[0].messageId] = tempImages
                            if let idxTemp = dataMessages.firstIndex(where: { $0["message_id"] as! String == tempImages[0].messageId }) {
                                for _ in 1..<tempImages.count {
                                    dataMessages.remove(at: idxTemp + 1)
                                }
                            }
                            tempImages.removeAll()
                        } else if tempImages.count != 0 {
                            tempImages.removeAll()
                        }
                        dataMessages.append(row)
                    }
                    if tempImages.count >= 4 {
                        if tempImages.count > 30 {
                            tempImages.removeSubrange(30..<tempImages.count)
                        }
                        groupImages[tempImages[0].messageId] = tempImages
                        if let idxTemp = dataMessages.firstIndex(where: { $0["message_id"] as! String == tempImages[0].messageId }) {
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
    
    func chatDate(stringDate: String) -> String {
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
    
    func updateProgress(_ data: [AnyHashable : Any]){
        var isImage = false
        var idx = dataMessages.lastIndex(where: { $0["video_id"] as? String == data["name"] as? String || $0["video_id"] as? String == data["video_id"] as? String })
        if (idx == nil) {
            idx = dataMessages.lastIndex(where: { $0["image_id"] as? String == data["name"] as? String || $0["image_id"] as? String == data["image_id"] as? String })
            isImage = true
        }
        if (idx != nil) {
            let section = dataDates.firstIndex(of: dataMessages[idx!]["chat_date"] as! String)
            if section == nil {
                return
            }
            let row = dataMessages.filter({ $0["chat_date"] as! String == dataDates[section!]}).firstIndex(where: { $0["message_id"] as? String == dataMessages[idx!]["message_id"] as? String})
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
                        if !(view is UILabel) && !(view is UIImageView) {
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
            idx = dataMessages.lastIndex(where: { $0["file_id"] as? String == data["name"] as? String || $0["file_id"] as? String == data["file_id"] as? String })
            if (idx != nil) {
                let section = dataDates.firstIndex(of: dataMessages[idx!]["chat_date"] as! String)
                if section == nil {
                    return
                }
                let row = dataMessages.filter({ $0["chat_date"] as! String == dataDates[section!]}).firstIndex(where: { $0["message_id"] as? String == dataMessages[idx!]["message_id"] as? String})
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
                            if !(view is UILabel) && !(view is UIImageView) {
                                for viewSubviews in view.subviews {
                                    if !(viewSubviews is UILabel) {
                                        for viewInContainer in viewSubviews.subviews {
                                            if !(viewInContainer is UILabel) && !(viewInContainer is UIImageView) {
                                                if viewInContainer.layer.sublayers!.count < 2 {
                                                    return
                                                }
                                                let loading = viewInContainer.layer.sublayers![1] as! CAShapeLayer
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
    
    @objc func onUploadChat(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        updateProgress(data)
    }
    
    
    @objc func onReceiveMessage(notification: NSNotification) {
        DispatchQueue.main.async { [self] in
            let data:[AnyHashable : Any] = notification.userInfo!
            if let dataMessage = data["message"] as? TMessage {
                let chatData = dataMessage.mBodies
                if (dataMessage.getCode() == CoreMessage_TMessageCode.PUSH_MEMBER_ROOM_CONTACT_CENTER && isContactCenter) {
                    let data = dataMessage.getBody(key: CoreMessage_TMessageKey.DATA)
                    if !data.isEmpty {
                        if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                            var members = ""
                            let idMe = User.getMyPin()!
                            var user : [User] = []
                            for json in jsonArray {
                                if "\(json)" != idMe {
                                    if members.isEmpty {
                                        members = "\(json)"
                                    } else {
                                        members += ",\(json)"
                                    }
                                    if let userData = User.getData(pin: "\(json)") {
                                        user.append(userData)
                                    } else {
                                        Nexilis.addFriend (fpin: "\(json)") { result in
                                            DispatchQueue.main.async {
                                                if result {
                                                    let userData = User.getData(pin: "\(json)")!
                                                    user.append(userData)
                                                } else {
                                                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                                    imageView.tintColor = .white
                                                    let banner = FloatingNotificationBanner(title: "Server busy, please try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                                                    banner.show()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            self.users = user
                            self.fPinContacCenter = members
                            self.changeAppBar()
                            SecureUserDefaults.shared.set(members, forKey: "inEditorPersonal")
                        }
                    }
                } else if (dataMessage.getCode() == CoreMessage_TMessageCode.ACCEPT_CALL_CENTER) {
                    if !self.isRequestContactCenter || !isContactCenter {
                        return
                    }
                    SecureUserDefaults.shared.set(dataMessage.getBody(key: CoreMessage_TMessageKey.F_PIN), forKey: "inEditorPersonal")
                    let date = Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                    self.fPinContacCenter = dataMessage.getBody(key: CoreMessage_TMessageKey.F_PIN)
                    self.complaintId = dataMessage.getBody(key: CoreMessage_TMessageKey.DATA)
                    self.channelContactCenter = dataMessage.getBody(key: CoreMessage_TMessageKey.CHANNEL)
                    var row: [String: Any?] = [:]
                    row["category_cc"] = "You are connecting with ".localized() + dataMessage.getBody(key: CoreMessage_TMessageKey.F_DISPLAY_NAME).trimmingCharacters(in: .whitespaces) + " at ".localized() + formatter.string(from: date as Date) + ".\n" + "In order to improve our service, all conversations will be recorded\naccording to state regulations".localized()
                    row["message_id"] = ""
                    row["message_text"] = "You are connecting with ".localized() + dataMessage.getBody(key: CoreMessage_TMessageKey.F_DISPLAY_NAME).trimmingCharacters(in: .whitespaces) + " at ".localized() + formatter.string(from: date as Date) + ".\n" + "In order to improve our service, all conversations will be recorded\naccording to state regulations".localized()
                    row["chat_date"] = "Today".localized()
                    self.dataMessages.append(row)
                    self.users.append(User.getData(pin: dataMessage.getBody(key: CoreMessage_TMessageKey.F_PIN))!)
                    self.changeAppBar()
                    self.setRightButtonItem()
                    self.dateStartCC = "\(Date().currentTimeMillis())"
                    self.tableChatView.insertRows(at: [IndexPath(row: self.dataMessages.count - 1, section: 0)], with: .none)
                    self.tableChatView.scrollToBottom()
                    SecureUserDefaults.shared.removeValue(forKey: "waitingRequestCC")
                    if dataMessage.getBody(key: CoreMessage_TMessageKey.CHANNEL) != "0" {
                        SecureUserDefaults.shared.set("\(Date().currentTimeMillis())", forKey: "startTimeCC")
                        SecureUserDefaults.shared.set(dataMessage.getBody(key: CoreMessage_TMessageKey.CHANNEL), forKey: "channelCC")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                            self.dismiss(animated: true, completion: nil)
                        })
                    } else {
                        viewButton.isHidden = false
                        viewTextfield.isHidden = false
                    }
                } else if (dataMessage.getCode() == CoreMessage_TMessageCode.INVITE_END_CONTACT_CENTER || dataMessage.getCode() == CoreMessage_TMessageCode.END_CALL_CENTER || dataMessage.getCode() == CoreMessage_TMessageCode.INVITE_EXIT_CONTACT_CENTER) && !fromVCAC {
                    let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
                    if onGoingCC.isEmpty || !isContactCenter {
                        return
                    }
                    let requester = onGoingCC.components(separatedBy: ",")[0]
                    let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
                    let fPin = dataMessage.getCode() == CoreMessage_TMessageCode.END_CALL_CENTER ? chatData[CoreMessage_TMessageKey.F_PIN] : dataMessage.getPIN()
                    if fPin == officer || fPin == requester {
                        DispatchQueue.global().async {
                            let date = "\(Date().currentTimeMillis())"
                            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                do {
                                    _ = try Database.shared.insertRecord(fmdb: fmdb, table: "CALL_CENTER_HISTORY", cvalues: [
                                        "type" : self.channelContactCenter,
                                        "title" : "Contact Center".localized(),
                                        "time" : self.dateStartCC,
                                        "f_pin" : officer,
                                        "data" : self.complaintId,
                                        "time_end" : date,
                                        "complaint_id" : self.complaintId,
                                        "members" : "",
                                        "requester": requester
                                    ], replace: true)
                                } catch {
                                    rollback.pointee = true
                                    print("Access database error: \(error.localizedDescription)")
                                }
                            })
                        }
                        self.dismissKeyboard()
                        self.disableEditor()
                        SecureUserDefaults.shared.removeValue(forKey: "onGoingCC")
                        SecureUserDefaults.shared.removeValue(forKey: "membersCC")
                        SecureUserDefaults.shared.removeValue(forKey: "waitingRequestCC")
                        DispatchQueue.main.async {
                            let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Call Center Session has ended".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
                            banner.show()
                        }
                        timeoutCC.invalidate()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                            if !(self.presentedViewController is EditorPersonal) {
                                self.dismiss(animated: true, completion: nil)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.dismiss(animated: true, completion: nil)
                            }
                        })
                    } else {
                        var members = ""
                        self.users.removeAll(where: {$0.pin == fPin})
                        for user in self.users {
                            if members.isEmpty {
                                members = "\(user.pin)"
                            } else {
                                members = ",\(user.pin)"
                            }
                        }
                        SecureUserDefaults.shared.set("\(members)", forKey: "membersCC")
                        self.fPinContacCenter = members
                        self.changeAppBar()
                    }
                }
                else if (chatData[CoreMessage_TMessageKey.F_PIN] == self.dataPerson["f_pin"]!! && !self.isContactCenter && (chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID] == "3")) || (self.isContactCenter && chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID] == "5" && self.complaintId == chatData[CoreMessage_TMessageKey.CALL_CENTER_ID]) {
                    if chatData[CoreMessage_TMessageKey.F_PIN] == nil {
                        return
                    }
                    let idx = self.dataMessages.firstIndex(where: { $0[TypeDataMessage.message_id] as? String == chatData[CoreMessage_TMessageKey.MESSAGE_ID]})
                    if idx != nil {
                        self.dataMessages[idx!][TypeDataMessage.message_text] = chatData[CoreMessage_TMessageKey.MESSAGE_TEXT]
                        self.dataMessages[idx!][TypeDataMessage.last_edit] = chatData[CoreMessage_TMessageKey.LAST_EDIT]
                        self.dataMessages[idx!][TypeDataMessage.status] = chatData[CoreMessage_TMessageKey.STATUS]
                        let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                        let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
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
                    row["chat_id"] = ""
                    if (chatData.keys.contains(CoreMessage_TMessageKey.FILE_ID)) {
                        row["file_id"] = chatData[CoreMessage_TMessageKey.FILE_ID]
                    } else {
                        row["file_id"] = ""
                    }
                    row["progress"] = 0.0
                    row["attachment_flag"] = chatData[CoreMessage_TMessageKey.ATTACHMENT_FLAG]
                    row["reff_id"] = chatData[CoreMessage_TMessageKey.REF_ID] ?? ""
                    row["lock"] = ""
                    row["is_stared"] = "0"
                    row["isSelected"] = false
                    if !self.dataDates.contains("Today".localized()) {
                        self.dataDates.append("Today".localized())
                        self.tableChatView.insertSections(IndexSet(integer: self.dataDates.count - 1), with: .none)
                    }
                    row["chat_date"] = "Today".localized()
                    row["blog_id"] = chatData[CoreMessage_TMessageKey.BLOG_ID]
                    self.counter += 1
                    if row["credential"] != nil && row["credential"] as! String == "1" {
                        self.listTimerCredential[row["message_id"] as! String] = 60
                    }
                    self.dataMessages.append(row)
                    self.tableChatView.insertRows(at: [IndexPath(row: self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[self.dataDates.count - 1]}).count - 1, section: self.dataDates.count - 1)], with: .none)
                    if row["credential"] != nil && row["credential"] as! String == "1" {
                        var timer = Timer()
                        var minute = 60
                        self.timerCredential[row["message_id"] as! String] = timer
                        SecureUserDefaults.shared.set("\(Date().currentTimeMillis())", forKey: row["message_id"] as! String)
                        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {_ in
                            minute -= 1
                            self.listTimerCredential[row["message_id"] as! String] = minute
                            if minute == 0 {
                                timer.invalidate()
                                self.listTimerCredential.removeValue(forKey: row["message_id"] as! String)
                                self.timerCredential.removeValue(forKey: row["message_id"] as! String)
                                SecureUserDefaults.shared.removeValue(forKey: row["message_id"] as! String)
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
                                            ], _where: "message_id = '\(row["message_id"] as! String)'")
                                        } catch {
                                            rollback.pointee = true
                                            print("Access database error: \(error.localizedDescription)")
                                        }
                                    })
                                }
                            }
                            self.tableChatView.reloadRows(at: [IndexPath(row: self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[self.dataDates.count - 1]}).count - 1, section: self.dataDates.count - 1)], with: .none)
                        })
                    }
                    if self.isContactCenter {
                        let idMe = User.getMyPin()!
                        let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
                        let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
                        if officer == idMe {
                            self.timeoutCC.invalidate()
                        } else {
                            if !self.showToast30s {
                                self.showToast(message: "Please reply within 30 seconds so the call center session doesn't end.".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                                sendTyping(l_pin: fPinContacCenter, isTyping: true)
                                self.showToast30s = true
                            }
                        }
                    }
                    if chatData[CoreMessage_TMessageKey.FORMAT] == "1" {
                        self.sendReadMessageStatus(chat_id: "", f_pin: chatData[CoreMessage_TMessageKey.F_PIN]!, message_scope_id: chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]!, message_id: chatData[CoreMessage_TMessageKey.MESSAGE_ID]!)
                        self.tableChatView.scrollToBottom()
                    } else if self.currentIndexpath?.row == (self.dataMessages.count - 2) {
                        if (self.viewIfLoaded?.window != nil) {
                            self.sendReadMessageStatus(chat_id: "", f_pin: chatData[CoreMessage_TMessageKey.F_PIN]!, message_scope_id: chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]!, message_id: chatData[CoreMessage_TMessageKey.MESSAGE_ID]!)
                        }
                        self.tableChatView.scrollToBottom()
                        if ( self.currentIndexpath!.section <= self.dataDates.count - 1 && self.currentIndexpath!.row <= self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[self.dataDates.count - 1]}).count - 1)  {
                            self.counter = 0
                            self.updateCounter(counter: self.counter)
                        }
                        let lastMarkerCounter = markerCounter
                        if self.markerCounter != nil {
                            self.markerCounter = nil
                        }
                        self.tableChatView.beginUpdates()
                        let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == lastMarkerCounter })
                        if indexMessage != nil {
                            let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"] as! String)
                            let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[indexMessage!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                            if row != nil && section != nil  {
                                self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                            }
                        }
                        self.tableChatView.endUpdates()
                    }
                    else if self.currentIndexpath == nil {
                        self.counter = 0
                        self.updateCounter(counter: self.counter)
                        if (self.viewIfLoaded?.window != nil) {
                            self.sendReadMessageStatus(chat_id: "", f_pin: chatData[CoreMessage_TMessageKey.F_PIN]!, message_scope_id: chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]!, message_id: chatData[CoreMessage_TMessageKey.MESSAGE_ID]!)
                        }
                    }
                    else if self.counter != 0 {
                        if !self.indicatorCounterBSTB.isDescendant(of: self.view) && self.buttonScrollToBottom.isDescendant(of: self.view) {
                            self.markerCounter = row["message_id"] as? String
                            self.addCounterAtButttonScrollToBottom()
                            self.tableChatView.beginUpdates()
                            let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.markerCounter })
                            if indexMessage != nil {
                                let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"] as! String)
                                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[indexMessage!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                                if row != nil && section != nil  {
                                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                }
                            }
                            self.tableChatView.endUpdates()
                        } else if self.indicatorCounterBSTB.isDescendant(of: self.view) {
                            self.labelCounter.text = "\(self.counter)"
                        }
                    }
                }
            } else if !self.isContactCenter {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
            }
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
        labelDisable.font = UIFont.systemFont(ofSize: 12).bold
        labelDisable.text = "Call center session is over".localized()
    }
    
    @objc func onStatusChat(notification: NSNotification) {
        DispatchQueue.main.async {
            let data:[AnyHashable : Any] = notification.userInfo!
            if let dataMessage = data["message"] as? TMessage {
                let chatData = dataMessage.mBodies
                let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
                let requester = onGoingCC.components(separatedBy: ",")[0]
                let idMe = User.getMyPin()!
                if chatData[CoreMessage_TMessageKey.F_PIN] == self.dataPerson["f_pin"]!! || chatData[CoreMessage_TMessageKey.L_PIN] == self.dataPerson["f_pin"]!! || chatData[CoreMessage_TMessageKey.L_PIN] == self.fPinContacCenter || requester == idMe {
                    if (chatData.keys.contains(CoreMessage_TMessageKey.MESSAGE_ID) && !(chatData[CoreMessage_TMessageKey.MESSAGE_ID]!).contains("-2,")) {
                        var idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == chatData[CoreMessage_TMessageKey.MESSAGE_ID]! })
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
                        var idx = self.dataMessages.firstIndex(where: { "'\(String(describing: $0["message_id"] as? String))'" == chatData["message_id"]! })
                        if let idxMessageIdParent = self.groupImages.firstIndex(where: { $0.value.contains(where: { $0.messageId == chatData["message_id"]! }) }) {
                            if let idxInImages = self.groupImages[idxMessageIdParent].value.firstIndex(where: { $0.messageId == chatData["message_id"]! }) {
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
            let messageId = data["message_id"] as! String
            let status = data["status"] as! String
            
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
                    let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                    let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
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
            if self.dataMessages[idx!]["lock"] != nil && self.dataMessages[idx!]["lock"] as! String == "1" {
                return
            }
            self.dataMessages[idx!]["lock"] = "1"
            self.dataMessages[idx!]["reff_id"] = ""
            let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
            let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
            if row != nil && section != nil  {
                self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
            }
            if self.listTimerCredential[self.dataMessages[idx!]["message_id"] as! String] != nil {
                self.listTimerCredential.removeValue(forKey: self.dataMessages[idx!]["message_id"] as! String)
                self.timerCredential[self.dataMessages[idx!]["message_id"] as! String]?.invalidate()
                self.timerCredential.removeValue(forKey: self.dataMessages[idx!]["message_id"] as! String)
                SecureUserDefaults.shared.removeValue(forKey: self.dataMessages[idx!]["message_id"] as! String)
            }
            if self.reffId != nil && self.reffId == chatData["message_id"]! {
                self.deleteReplyView()
            }
        } catch {
        }
    }
    
    private func updateStatusMessage(idx: Int?, chatData: [String: String]) {
        do {
            if Int(self.dataMessages[idx!]["status"] as! String)! > Int(chatData[CoreMessage_TMessageKey.STATUS]!)! {
                return
            }
            self.dataMessages[idx!]["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
            let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
            let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
            if row != nil && section != nil  {
                self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
            }
        } catch {
        }
    }
    
    @objc func onTyping(notification: NSNotification) {
        DispatchQueue.main.async { [self] in
            let data:[AnyHashable : Any] = notification.userInfo!
            let message: TMessage = data["message"] as! TMessage
            let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
            if !onGoingCC.isEmpty {
                let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
                if message.getBody(key: CoreMessage_TMessageKey.F_PIN) != officer {
                    //print("RESET TIMER")
//                    timeoutCC.invalidate()
//                    timeoutCC = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false, block: {_ in
//                        let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
//                        imageView.tintColor = .white
//                        let banner = FloatingNotificationBanner(title: "Customer doesn't respond in 30 second, so call center session will be ended automatically.".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
//                        banner.show()
//                        self.endCallCenter()
//                    })
                }
            } else {
                
            }
        }
    }
    
    @objc func onUnfriend(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        DispatchQueue.main.async { [self] in
            if data["state"] as! Int == 99 && (data["message"] as! String).components(separatedBy: ",")[0] == "delete_buddy" {
                removed = true
                if forwardSession || copySession || deleteSession || isSearching {
                    cancelAction()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {[self] in
                    navigationItem.rightBarButtonItem = nil
                    navigationItem.rightBarButtonItems = nil
                    changeAppBar()
                    view.addSubview(containerAction)
                    containerAction.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        containerAction.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                        containerAction.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                        containerAction.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                        containerAction.heightAnchor.constraint(equalToConstant: 120)
                    ])
                    containerAction.backgroundColor = .secondaryColor.withAlphaComponent(0.8)
                    let labelUnfriend = UILabel()
                    containerAction.addSubview(labelUnfriend)
                    labelUnfriend.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        labelUnfriend.centerYAnchor.constraint(equalTo: containerAction.centerYAnchor),
                        labelUnfriend.centerXAnchor.constraint(equalTo: containerAction.centerXAnchor),
                    ])
                    labelUnfriend.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
                    labelUnfriend.font = UIFont.systemFont(ofSize: 12).bold
                    labelUnfriend.text = "You have unfriended this user".localized()
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
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
            } else if data["state"] as! Int == 01 {
                if let dataMessage = try! JSONSerialization.jsonObject(with: (data["message"] as! String).data(using: .utf8)!, options: []) as? [String: String] {
                    if(dataMessage["l_pin"] == dataPerson["f_pin"]!){
                        if let block = dataMessage["block"] {
                            if(block == "-1"){
                                dismissKeyboard()
                            }
                            blockedView(blocked: block)
                            if contactChatNav.viewIfLoaded?.window != nil {
                                contactChatNav.dismiss(animated: true)
                            }
                            cancelAction()
                        }
                    }
                    setRightButtonItem()
                }
            }
        }
    }
    
    func blockedView(blocked: String) {
        dismissKeyboard()
        view.addSubview(containerAction)
        containerAction.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerAction.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            containerAction.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            containerAction.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            containerAction.heightAnchor.constraint(equalToConstant: 120)
        ])
        containerAction.backgroundColor = .secondaryColor.withAlphaComponent(0.8)
        let labelBlocked = UILabel()
        containerAction.addSubview(labelBlocked)
        labelBlocked.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelBlocked.centerYAnchor.constraint(equalTo: containerAction.centerYAnchor),
            labelBlocked.centerXAnchor.constraint(equalTo: containerAction.centerXAnchor),
        ])
        labelBlocked.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        labelBlocked.font = UIFont.systemFont(ofSize: 12).bold
        if blocked == "1" {
            labelBlocked.text = "You blocked this user".localized()
        } else {
            labelBlocked.text = "You have been blocked by this user".localized()
        }
    }
    
    @objc func seeProfileTapped() {
        if dataPerson["f_pin"] == "-999" || dataPerson["isOfficial"] == "1" || removed || copySession || forwardSession || deleteSession || isContactCenter {
            return
        }
        dismissKeyboard()
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
        controller.data = dataPerson["f_pin"]!!
        controller.checkReadMessage = {
            self.dataPerson.removeAll()
            self.getDataProfile(fPin: self.unique_l_pin)
            self.changeAppBar()
            if self.currentIndexpath == nil {
                var listData = self.dataMessages
                listData = listData.filter({$0["status"] as! String != "4" && $0["status"] as! String != "8"})
                if listData.count != 0 && !self.isContactCenter {
                    let idMe = User.getMyPin() as String?
                    for i in 0...listData.count - 1 {
                        if listData[i]["f_pin"] as? String != idMe {
                            self.sendReadMessageStatus(chat_id: "", f_pin: self.dataPerson["f_pin"]!!, message_scope_id: "3", message_id: listData[i]["message_id"] as! String)
                        }
                    }
                }
            } else {
                let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[self.currentIndexpath!.section] })
                var listData = dataMessages
                listData = listData.filter({$0["status"] as! String != "4" && $0["status"] as! String != "8"})
                if listData.count != 0 && !self.isContactCenter {
                    let idMe = User.getMyPin() as String?
                    for i in 0...listData.count - 1 {
                        if listData[i]["f_pin"] as? String != idMe {
                            self.sendReadMessageStatus(chat_id: "", f_pin: self.dataPerson["f_pin"]!!, message_scope_id: "3", message_id: listData[i]["message_id"] as! String)
                        }
                    }
                }
            }
        }
        navigationController?.show(controller, sender: nil)
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
        if isContactCenter && fPinContacCenter.isEmpty && isRequestContactCenter {
            return
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
                imageVideoPicker.present(source: .imageAlbum)
            case "video":
                imageVideoPicker.present(source: .videoAlbum)
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
        if isContactCenter && fPinContacCenter.isEmpty && isRequestContactCenter {
            return
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
        if isContactCenter && fPinContacCenter.isEmpty && isRequestContactCenter {
            return
        }
        DispatchQueue.main.async {
            if (self.constraintBottomAttachment.constant == 0.0) {
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
        if isContactCenter && fPinContacCenter.isEmpty && isRequestContactCenter {
            return
        }
        if (self.constraintBottomAttachment.constant != 0.0) {
            constraintBottomAttachment.constant = 0.0
            self.viewSticker.removeConstraints(self.viewSticker.constraints)
            self.viewSticker.removeFromSuperview()
        }
        documentPicker.present()
    }
    
    @objc func sendTapped() {
        sendChat(message_text: textFieldSend.text!, viewController: self)
    }
    
    @objc func showChooserACKConfidential() {
        let alertController = LibAlertController(title: "Message Mode".localized(), message: "Select".localized() + " " + "Message Mode".localized(), preferredStyle: .actionSheet)
        let imageConfidential = resizeImage(image: UIImage(named: "confidential_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
        let imageAck = resizeImage(image: UIImage(named: "ack_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
        let confidentialAction = UIAlertAction(title: "Confidential Message".localized(), style: .default, handler: { (UIAlertAction) in
            if !self.isConfidential {
                self.isConfidential = true
                self.buttonAckConfidential.setImage(imageConfidential, for: .normal)
            }
            if self.isAck {
                self.isAck = false
            }
        })
        let ackAction = UIAlertAction(title: "Confirmation Message".localized(), style: .default, handler: { (UIAlertAction) in
            if !self.isAck {
                self.isAck = true
                self.buttonAckConfidential.setImage(imageAck, for: .normal)
            }
            if self.isConfidential {
                self.isConfidential = false
            }
        })
        confidentialAction.setValue(imageConfidential, forKey: "image")
        ackAction.setValue(imageAck, forKey: "image")
        alertController.addAction(confidentialAction)
        alertController.addAction(ackAction)
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
    
    @objc func addRoom(sender: UIBarButtonItem) {
        let controller = QmeraCallContactViewController()
        controller.isDismiss = { user in
            DispatchQueue.global().async {
                _ = Nexilis.write(message: CoreMessage_TMessageBank.getCCRoomInvite(l_pin: user.pin, ticket_id: self.complaintId, channel: self.channelContactCenter))
            }
        }
        controller.selectedUser.append(contentsOf: users)
        controller.isInviteCC = true
        self.navigationController?.show(controller, sender: nil)
    }
    
    @objc func audioVideoCall(sender: UIBarButtonItem) {
        if sender.tag == 0 {
            if !Nexilis.checkingAccess(key: "audio_call") {
                showToast(message: "Feature disabled..".localized(), font: UIFont.systemFont(ofSize: 12), controller: self)
                return
            }
            let goAudioCall = Nexilis.checkMicPermission()
            if !goAudioCall{
                let alert = LibAlertController(title: "Attention!".localized(), message: "Please allow microphone permission in your settings".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: {_ in
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }))
                self.navigationController?.present(alert, animated: true, completion: nil)
                return
            }
            if let pin = dataPerson["f_pin"] {
                if !CheckConnection.isConnectedToNetwork() {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                }
                let controller = QmeraAudioViewController()
                controller.user = User.getData(pin: pin)
                controller.isOutgoing = true
                controller.modalPresentationStyle = .overCurrentContext
                present(controller, animated: true, completion: nil)
            }
        } else {
            if !Nexilis.checkingAccess(key: "video_call") {
                showToast(message: "Feature disabled..".localized(), font: UIFont.systemFont(ofSize: 12), controller: self)
                return
            }
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
            if !CheckConnection.isConnectedToNetwork() {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            let videoVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "videoVCQmera") as! QmeraVideoViewController
            videoVC.dataPerson.append(dataPerson)
            self.show(videoVC, sender: nil)
        }
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
    
    @objc func didTapExit() {
        if complaintId.isEmpty || fromVCAC {
            for timer in self.timerCredential.values {
                timer.invalidate()
            }
            self.timeoutCC.invalidate()
            SecureUserDefaults.shared.removeValue(forKey: "inEditorPersonal")
            NotificationCenter.default.removeObserver(self)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshView"), object: nil, userInfo: nil)
            self.dismiss(animated: true, completion: nil)
        } else if !complaintId.isEmpty {
            let alert = LibAlertController(title: "Interaction with Call Center is in progress".localized(), message: "Are you sure you want to end the Call Center?".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: {(_) in
                self.endCallCenter()
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    public func endCallCenter() {
        timeoutCC.invalidate()
        let complaintId = self.complaintId
        let idMe = User.getMyPin()!
        let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
        let requester = onGoingCC.components(separatedBy: ",")[0]
        let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
        DispatchQueue.global().async {
            let date = "\(Date().currentTimeMillis())"
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    _ = try Database.shared.insertRecord(fmdb: fmdb, table: "CALL_CENTER_HISTORY", cvalues: [
                        "type" : self.channelContactCenter,
                        "title" : "Contact Center".localized(),
                        "time" : self.dateStartCC,
                        "f_pin" : officer,
                        "data" : self.complaintId,
                        "time_end" : date,
                        "complaint_id" : self.complaintId,
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
            SecureUserDefaults.shared.removeValue(forKey: "waitingRequestCC")
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.viewIfLoaded?.window != nil {
            let info:NSDictionary = notification.userInfo! as NSDictionary
            let duration: CGFloat = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber as! CGFloat
            
            self.constraintViewTextField.constant = 0
            self.constraintBottomContainerMultpileSelectSession.constant = 0
            UIView.animate(withDuration: TimeInterval(duration), animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if self.viewIfLoaded?.window != nil {
            if (self.constraintBottomAttachment.constant != 0.0) {
                self.constraintBottomAttachment.constant = 0.0
                self.viewSticker.removeConstraints(self.viewSticker.constraints)
                self.viewSticker.removeFromSuperview()
            }
            let info:NSDictionary = notification.userInfo! as NSDictionary
            let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            
            let keyboardHeight: CGFloat = keyboardSize.height
            
            let duration: CGFloat = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber as! CGFloat
            
            if self.constraintViewTextField.constant != keyboardHeight - 60 {
                self.constraintViewTextField.constant = keyboardHeight - 60
                if isSearching {
                    self.constraintViewTextField.constant = self.constraintViewTextField.constant + 60
                    self.constraintBottomContainerMultpileSelectSession.constant = -keyboardHeight
                }
                UIView.animate(withDuration: TimeInterval(duration), animations: {
                    self.view.layoutIfNeeded()
                })
                if isSearching {
                    self.tableChatView.scrollToBottom()
                } else {
                    if (self.currentIndexpath != nil) {
                        self.tableChatView.scrollToRow(at: IndexPath(row: self.currentIndexpath!.row, section: self.currentIndexpath!.section), at: .none, animated: false)
                    } else {
                        self.tableChatView.scrollToBottom()
                    }
                }
            }
        }
    }
    
    private func sendChat(message_scope_id:String =  "3", status:String =  "1", message_text:String =  "", credential:String = "0", attachment_flag: String = "0", ex_blog_id: String = "", message_large_text: String = "", ex_format: String = "", image_id: String = "", audio_id: String = "", video_id: String = "", file_id: String = "", thumb_id: String = "", reff_id: String = "", read_receipts: String = "4", chat_id: String = "", is_call_center: String = "0", call_center_id: String = "", viewController: UIViewController, isAutoSendCC : Bool = false) {
        if viewController is EditorPersonal && file_id == "" && dataMessageForward == nil && !isAutoSendCC{
            if ((textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) == "Send message".localized() && textFieldSend.textColor == UIColor.lightGray && attachment_flag != "11") || textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ) {
                dismissKeyboard()
                viewController.showToast(message: "Write Messages".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
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
        var is_call_center = is_call_center
        var call_center_id = call_center_id
        var l_pin = dataPerson["f_pin"]!!
        var message_scope_id = message_scope_id
        var chat_id = chat_id
        
        if (isContactCenter) {
            if fPinContacCenter.isEmpty && isRequestContactCenter {
                if textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "Send message".localized() && textFieldSend.textColor != UIColor.lightGray && constraintViewTextField.constant == 0 {
                    textFieldSend.text = "Send message".localized()
                    textFieldSend.textColor = UIColor.lightGray
                } else if constraintViewTextField.constant != 0 {
                    textFieldSend.text = ""
                }
                dismissKeyboard()
                viewController.showToast(message: "Unable to send message. Waiting for the officer to accept your request".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                return
            }
            is_call_center = "1"
            call_center_id = complaintId
            l_pin = fPinContacCenter
            message_scope_id = "5"
            chat_id = complaintId
            if isAutoSendCC {
                timeoutCC = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false, block: {_ in
                    let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Customer doesn't respond in 30 second, so call center session will be ended automatically.".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
                    banner.show()
                    self.endCallCenter()
                })
            }
        }
        let message_text = message_text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let idMe = User.getMyPin() as String?
        var opposite_pin = ""
        if isContactCenter {
            opposite_pin = ""
        } else {
            opposite_pin = idMe ?? ""
        }
        var credential = credential
        if isConfidential {
            credential = "1"
        }
        var read_receipts = read_receipts
        if isAck {
            read_receipts = "8"
        }
        sendTyping(l_pin: l_pin, isTyping: true)
        let message = CoreMessage_TMessageBank.sendMessage(l_pin: l_pin, message_scope_id: message_scope_id, status: status, message_text: message_text, credential: credential, attachment_flag: attachment_flag, ex_blog_id: ex_blog_id, message_large_text: message_large_text, ex_format: ex_format, image_id: image_id, audio_id: audio_id, video_id: video_id, file_id: file_id, thumb_id: thumb_id, reff_id: reff_id, read_receipts: read_receipts, chat_id: chat_id, is_call_center: is_call_center, call_center_id: call_center_id, opposite_pin: opposite_pin)
        Nexilis.addQueueMessage(message: message)
        let messageId = String(message.mBodies[CoreMessage_TMessageKey.MESSAGE_ID]!)
        if credential == "1" {
            self.listTimerCredential[messageId] = 60
        }
        var row: [String: Any?] = [:]
        row["message_id"] = messageId
        row["f_pin"] = idMe
        row["l_pin"] = dataPerson["f_pin"]!!
        row["message_scope_id"] = message_scope_id
        row["server_date"] = "\(Date().currentTimeMillis())"
        row["status"] = status
        row["message_text"] = message_text
        row["audio_id"] = audio_id
        row["video_id"] = video_id
        row["image_id"] = image_id
        row["thumb_id"] = thumb_id
        row["read_receipts"] = read_receipts
        row["credential"] = credential
        row["chat_id"] = chat_id
        row["file_id"] = file_id
        row["blog_id"] = ex_blog_id
        row["attachment_flag"] = attachment_flag
        row["reff_id"] = reff_id
        row["progress"] = 0.0
        row["lock"] = "0"
        row["is_stared"] = "0"
        row["isSelected"] = false
        row[TypeDataMessage.is_call_center] = is_call_center
        row[TypeDataMessage.call_center_id] = call_center_id
        row[TypeDataMessage.opposite_pin] = opposite_pin
        if !dataDates.contains("Today".localized()) {
            dataDates.append("Today".localized())
            tableChatView.insertSections(IndexSet(integer: dataDates.count - 1), with: .none)
        }
        row["chat_date"] = "Today".localized()
        dataMessages.append(row)
        tableChatView.insertRows(at: [IndexPath(row: dataMessages.filter({ $0["chat_date"] as! String == dataDates[dataDates.count - 1]}).count - 1, section: dataDates.count - 1)], with: .none)
        if credential == "1" {
            var timer = Timer()
            var minute = 60
            self.timerCredential[messageId] = timer
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
                self.tableChatView.reloadRows(at: [IndexPath(row: self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[self.dataDates.count - 1]}).count - 1, section: self.dataDates.count - 1)], with: .none)
            })
        }
        if textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "Send message".localized() && textFieldSend.textColor != UIColor.lightGray && constraintViewTextField.constant == 0 {
            textFieldSend.text = "Send message".localized()
            textFieldSend.textColor = UIColor.lightGray
        } else if constraintViewTextField.constant != 0 {
            textFieldSend.text = ""
            heightTextFieldSend.constant = 40
        }
        deleteReplyView()
        deleteLinkPreview()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.tableChatView.scrollToBottom()
            if self.markerCounter != nil {
                let lastMarkerCounter = self.markerCounter
                self.markerCounter = nil
                self.tableChatView.beginUpdates()
                let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == lastMarkerCounter })
                if indexMessage != nil {
                    let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"] as! String)
                    let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[indexMessage!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                    if row != nil && section != nil  {
                        self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                    }
                }
                self.tableChatView.endUpdates()
            }
        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            self.timerFakeProgress = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//                self.updateProgress(row as [AnyHashable : Any])
//                if self.fakeProgMultip == self.maxFakeProgMultip {
//                    self.timerFakeProgress?.invalidate()
//                    self.fakeProgMultip = 0
//                }
//            }
//        }
    }
    
    @objc func ccAction(sender: UIButton) {
        if self.nowSelectedCategoryCC == "CantReturn" {
            if sender.tag == 503 {
                self.showToast(message: "You can't request Call Center more than one".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
            } else if sender.tag == 504 {
                busyCCAction(sender: sender)
            }
            return
        }
        if self.nowSelectedCategoryCC == "endCC" {
            return
        }
        let id = sender.restorationIdentifier?.components(separatedBy: ",")[0]
        let service_id = sender.restorationIdentifier?.components(separatedBy: ",")[1]
        let level = id!.substring(from: 5, to: 5)
        let levelNow = self.nowSelectedCategoryCC.substring(from: 5, to: 5)
        var isRequest = false
        var channel = 0
        var row: [String: Any?] = [:]
        if nowSelectedCategoryCC.isEmpty || level > levelNow {
            if Utils.getDefaultCC() == "No" && !showToastTwiceClick {
                self.showToast(message: "You can press your choice again to change category".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                showToastTwiceClick = true
            }
            row["message_id"] = ""
            row["chat_date"] = "Today".localized()
            let dataChat: [CategoryCC] = CategoryCC.getDatafromParent(parent: service_id!)
            if dataChat.count != 0 {
                var data : [CategoryCC] = []
                for i in 0..<dataChat.count {
                    data.append(CategoryCC(id: "level\(Int(level)! + 1)_\(i)", service_id: dataChat[i].service_id, service_name: dataChat[i].service_name, parent: id!, description: dataChat[i].description, is_tablet: dataChat[i].is_tablet))
                }
                row["category_cc"] = data
            } else if dataMessages[Int(level)!]["attachment_flag"] == nil {
                let listStringName: [String] = ["Informasi Umum Produk Call 1500046", "Informasi Spesifik Produk"]
                var data : [CategoryCC] = []
                for i in 0..<listStringName.count {
                    data.append(CategoryCC(id: "level\(Int(level)! + 1)_\(i)", service_id: service_id!, service_name: listStringName[i], parent: id!, description: "", is_tablet: "0"))
                }
                row["category_cc"] = data
                row["attachment_flag"] = "502"
            } else if dataMessages[Int(level)!]["attachment_flag"] != nil && dataMessages[Int(level)!]["attachment_flag"] as! String == "502" {
                if id == "level\(Int(level)!)_0" {
                    if let url = URL(string: "tel://1500046") {
                        UIApplication.shared.open(url)
                    }
                    return
                } else {
                    let listStringName: [String] = ["Messaging".localized(), "Secure SMS".localized(), "VoIP Call".localized(), "Email".localized(), "Video Call".localized(), "GSM Call".localized(), "GPT Chatbot".localized(), "WhatsApp"]
//                    let listStringName: [String] = ["Chat with a Representative".localized(), "Video Call a Representative".localized(), "Call a Representative".localized()]
                    var data : [CategoryCC] = []
                    let channels : [String] = ["0", "4", "1", "3", "2", "5", "7", "6"]
                    for i in 0..<listStringName.count {
                        data.append(CategoryCC(id: "level\(Int(level)! + 1)_\(channels[i])", service_id: service_id!, service_name: listStringName[i], parent: id!, description: "", is_tablet: "0"))
                    }
                    row["category_cc"] = data
                    row["attachment_flag"] = "503"
                }
            } else {
                channel = Int((id?.components(separatedBy: "_")[1])!)!
                if channel == 1 || channel == 2 {
                    if channel == 2 {
                        let goAudioCall = Nexilis.checkMicPermission()
                        let goVideoCall = Nexilis.checkCameraPermission()
                        if goVideoCall == 0 {
                            let alert = LibAlertController(title: "Attention!".localized(), message: !goAudioCall && goVideoCall == 0 && channel == 2 ? "Please allow microphone & camera permission in your settings".localized() : !goAudioCall ? "Please allow microphone permission in your settings".localized() : "Please allow camera permission in your settings", preferredStyle: .alert)
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
                    } else if channel == 1 {
                        let goAudioCall = Nexilis.checkMicPermission()
                        if !goAudioCall{
                            let alert = LibAlertController(title: "Attention!".localized(), message: "Please allow microphone permission in your settings".localized(), preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: {_ in
                                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                }
                            }))
                            self.navigationController?.present(alert, animated: true, completion: nil)
                            return
                        }
                    }
                } else if channel == 3 {
                    requestEmailContactCenter(channel)
                    return
                } else if channel == 4 {
                    requestSMSContactCenter(channel)
                    return
                } else if channel == 5 {
                    requestGSMCallContactCenter(channel)
                    return
                } else if channel == 6 {
                    requestWhatsappContactCenter(channel)
                    return
                } else if channel == 7 {
                    APIS.openSmartChatbot()
                    return
                }
                row["category_cc"] = "Please wait while we connect you\nto one of our service representatives".localized()
                isRequest = true
            }
            if dataMessages[Int(level)!]["attachment_flag"] == nil || dataMessages[Int(level)!]["attachment_flag"] as! String != "503" {
                dataMessages.append(row)
                self.nowSelectedCategoryCC = id!
                tableChatView.insertRows(at: [IndexPath(row: dataMessages.count - 1, section: 0)], with: .none)
            }
        } else {
            if id == self.nowSelectedCategoryCC {
                if level == "0" {
                    self.nowSelectedCategoryCC = ""
                } else {
                    let categoryCC = dataMessages[dataMessages.count - 2]["category_cc"] as! [CategoryCC]
                    self.nowSelectedCategoryCC = categoryCC[0].parent
                }
                tableChatView.beginUpdates()
                tableChatView.deleteRows(at: [IndexPath(row: dataMessages.count - 1, section: 0)], with: .none)
                dataMessages.remove(at: dataMessages.count - 1)
                tableChatView.endUpdates()
            } else {
                return
            }
        }
        if Utils.getDefaultCC() == "No" {
            if sender.backgroundColor != .orangeBNI {
                var button = dataMessages[dataMessages.count - 2]["category_cc"] as! [CategoryCC]
                if dataMessages[Int(level)!]["attachment_flag"] != nil && dataMessages[Int(level)!]["attachment_flag"] as! String == "503" {
                    button = dataMessages[dataMessages.count - 1]["category_cc"] as! [CategoryCC]
                }
                for i in button {
                    if i.id == id! {
                        i.isActive = true
                        break
                    }
                }
                sender.backgroundColor = .orangeBNI
                dataMessages[dataMessages.count - 2]["category_cc"] = button
            } else {
                let button = dataMessages[dataMessages.count - 1]["category_cc"] as! [CategoryCC]
                for i in button {
                    if i.id == id! {
                        i.isActive = false
                        break
                    }
                }
                sender.backgroundColor = .clear
                dataMessages[dataMessages.count - 1]["category_cc"] = button
            }
        }
        if isRequest {
            requestContactCenter(channel: channel, service_id: service_id!, row: row)
        } else {
            self.tableChatView.scrollToBottom()
        }
    }
    
    private func directCC() {
        if channelContactCenter == "1" || channelContactCenter == "2" {
            if channelContactCenter == "2" {
                let goAudioCall = Nexilis.checkMicPermission()
                let goVideoCall = Nexilis.checkCameraPermission()
                if goVideoCall == 0 {
                    let alert = LibAlertController(title: "Attention!".localized(), message: !goAudioCall && goVideoCall == 0 && channelContactCenter == "2" ? "Please allow microphone & camera permission in your settings".localized() : !goAudioCall ? "Please allow microphone permission in your settings".localized() : "Please allow camera permission in your settings", preferredStyle: .alert)
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
            } else if channelContactCenter == "1" {
                let goAudioCall = Nexilis.checkMicPermission()
                if !goAudioCall{
                    let alert = LibAlertController(title: "Attention!".localized(), message: "Please allow microphone permission in your settings".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: {_ in
                        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }))
                    self.navigationController?.present(alert, animated: true, completion: nil)
                    return
                }
            }
        }
        var row: [String: Any?] = [:]
        row["message_id"] = ""
        row["chat_date"] = "Today".localized()
        row["category_cc"] = "Please wait while we connect you\nto one of our service representatives".localized()
        dataMessages.append(row)
        nowSelectedCategoryCC = "CantReturn"
        tableChatView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        requestContactCenter(channel: Int(channelContactCenter)!, service_id: serviceIdCC, row: row)
    }
    
    @objc func busyCCAction(sender: UIButton) {
        let id = sender.restorationIdentifier?.components(separatedBy: ",")[0]
        let service_id = sender.restorationIdentifier?.components(separatedBy: ",")[1]
        let level = id!.substring(from: 5, to: 5)
        var row: [String: Any?] = [:]
        if id == "level\(Int(level)!)_0" {
            SecureUserDefaults.shared.set(true, forKey: "waitingRequestCC")
            DispatchQueue.global().async {
                let message = CoreMessage_TMessageBank.getQueuingCallCenter(p_channel: Int(self.channelContactCenter)!)
                message.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = "\(service_id!)"
                _ = Nexilis.writeSync(message: message, timeout: 30 * 1000)
            }
            row["category_cc"] = "Thank you for contacting us,\none of our officers will contact you soon".localized()
        } else {
            row["category_cc"] = "Thank you for being awesome,\nhave a great day!".localized()
        }
        row["message_id"] = ""
        row["chat_date"] = "Today".localized()
        self.nowSelectedCategoryCC = "endCC"
        dataMessages.append(row)
        tableChatView.insertRows(at: [IndexPath(row: Int(level)!, section: 0)], with: .none)
        self.tableChatView.scrollToBottom()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
//            self.dismiss(animated: true)
//        })
    }
    
    func requestEmailContactCenter(_ channel: Int){
        let idMe = User.getMyPin() as String?
        let complaintId = "CMP_\(idMe!)_\(String(Date().currentTimeMillis()))EML"
        let message = CoreMessage_TMessageBank.getRequestEmailCallCenter(p_channel: channel)
        if let response = Nexilis.writeSync(message: message) {
            if (response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "00") {
                DispatchQueue.main.async {
                    let email = response.getBody(key: CoreMessage_TMessageKey.EMAIL, default_value: "")
                    let officer = response.getBody(key: CoreMessage_TMessageKey.L_PIN, default_value: "")
                    if email.isEmpty {
                        self.showToast(message: "Invalid Email Address".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                        return
                    }
                    // TODO: check if mail available
                    Nexilis.openmailAction(to: email)
                }
            }
        }
        
    }
    
    func requestSMSContactCenter(_ channel: Int){
//        let idMe = User.getMyPin()!
//        let complaintId = "CMP_\(idMe)_\(String(Date().currentTimeMillis()))SMS"
//        isRequestContactCenter = true
        var phone = Utils.getSMSCenter()
        if phone.substring(from: 0, to: 0) == "0" {
            phone = "+62" + phone.substring(from: 1, to: phone.count)
        }
        APIS.sendSMS(phoneNumber: phone)
//        let tmessage = TMessage()
//        tmessage.mCode = CoreMessage_TMessageCode.ACCEPT_CALL_CENTER
//        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
//        tmessage.mPIN = idMe
//        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
//        tmessage.mBodies[CoreMessage_TMessageKey.UPLINE_PIN] = me
//        tmessage.mBodies[CoreMessage_TMessageKey.CHANNEL] = channel
//        tmessage.mBodies[CoreMessage_TMessageKey.CALL_CENTER_ID] = complaint_id
    }
    
    func requestGSMCallContactCenter(_ channel: Int){
        var phone = Utils.getCallCenter()
        if phone.substring(from: 0, to: 0) == "0" {
            phone = "+62" + phone.substring(from: 1, to: phone.count)
        }
        if let url = URL(string: "tel://\(phone)") {
            UIApplication.shared.open(url)
        }
    }
    
    func requestWhatsappContactCenter(_ channel: Int){
        var phone = Utils.getWhatsappCenter()
        if phone.substring(from: 0, to: 0) == "0" {
            phone = "+62" + phone.substring(from: 1, to: phone.count)
        }
        APIS.sendWhatsapp(phoneNumber: phone)
    }
    
    func requestContactCenter(channel: Int, service_id: String, row: [String: Any?]) {
        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        DispatchQueue.global().async {
            let message = CoreMessage_TMessageBank.getRequestCallCenter(p_channel: channel, category_id: service_id)
            if let response = Nexilis.writeSync(message: message) {
                if !self.isDirectCC {
                    DispatchQueue.main.async {
                        self.dataMessages.append(row)
                        self.nowSelectedCategoryCC = "CantReturn"
                        self.tableChatView.insertRows(at: [IndexPath(row: self.dataMessages.count - 1, section: 0)], with: .none)
                        self.tableChatView.scrollToBottom()
                    }
                }
                if (response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "00") {
                    DispatchQueue.main.async {
                        SecureUserDefaults.shared.set(true, forKey: "waitingRequestCC")
                        let data = response.getBody(key: CoreMessage_TMessageKey.DATA, default_value: "")
                        if data.isEmpty {
                            SecureUserDefaults.shared.removeValue(forKey: "waitingRequestCC")
                            var row: [String: Any?] = [:]
                            row["message_id"] = ""
                            row["chat_date"] = "Today".localized()
                            row["attachment_flag"] = "504"
                            let listStringName: [String] = ["Yes".localized(), "No".localized()]
                            var data : [CategoryCC] = []
                            for i in 0..<listStringName.count {
                                data.append(CategoryCC(id: "level\(self.dataMessages.count + 1)_\(i)", service_id: service_id, service_name: listStringName[i], parent: "", description: "", is_tablet: "0"))
                            }
                            row["category_cc"] = data
                            self.dataMessages.append(row)
                            self.channelContactCenter = "\(channel)"
                            self.tableChatView.insertRows(at: [IndexPath(row: self.dataMessages.count - 1, section: 0)], with: .none)
                            self.tableChatView.scrollToBottom()
                        } else {
                            self.fPinContacCenter = data
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        SecureUserDefaults.shared.removeValue(forKey: "waitingRequestCC")
                        var row: [String: Any?] = [:]
                        row["message_id"] = ""
                        row["chat_date"] = "Today".localized()
                        row["attachment_flag"] = "504"
                        let listStringName: [String] = ["Yes".localized(), "No".localized()]
                        var data : [CategoryCC] = []
                        for i in 0..<listStringName.count {
                            data.append(CategoryCC(id: "level\(self.dataMessages.count + 1)_\(i)", service_id: service_id, service_name: listStringName[i], parent: "", description: "", is_tablet: "0"))
                        }
                        row["category_cc"] = data
                        self.dataMessages.append(row)
                        self.channelContactCenter = "\(channel)"
                        self.tableChatView.insertRows(at: [IndexPath(row: self.dataMessages.count - 1, section: 0)], with: .none)
                        self.tableChatView.scrollToBottom()
                    }
                }
            }
        }
    }
    
    private func sendReadMessageStatus(chat_id: String, f_pin: String, message_scope_id: String, message_id: String) {
        let message = CoreMessage_TMessageBank.getUpdateRead(p_chat_id: chat_id, p_f_pin: f_pin, p_scope_id: message_scope_id, qty: 1)
        let fPin = message.getBody(key: CoreMessage_TMessageKey.F_PIN)
        let scope = message.getBody(key: CoreMessage_TMessageKey.SCOPE_ID)
        message.mBodies[CoreMessage_TMessageKey.SERVER_DATE] = String(Date().currentTimeMillis())
        if (fPin.elementsEqual("-999") || scope.elementsEqual("16") || scope.elementsEqual("15")){
            return
        }
        DispatchQueue.global().async {
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
                    message.mStatus = CoreMessage_TMessageUtil.getTID()
                    message.mBodies[CoreMessage_TMessageKey.L_PIN] = f_pin
                    message.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = "-2,\(valueListGroupImages[i].messageId)"
                    _ = Nexilis.write(message: message)
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
                message.mStatus = CoreMessage_TMessageUtil.getTID()
                message.mBodies[CoreMessage_TMessageKey.L_PIN] = f_pin
                message.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = "-2,\(message_id)"
                _ = Nexilis.write(message: message)
            }
        }
        if let index = dataMessages.firstIndex(where: {$0["message_id"] as? String == message_id}) {
            dataMessages[index]["status"] = "4"
            let auto: Bool = SecureUserDefaults.shared.value(forKey: "autoDownload") ?? false
            if auto {
                if dataMessages[index]["image_id"] as? String != nil && !((dataMessages[index]["image_id"] as? String)!.isEmpty) {
                    if let listGroupImages = self.groupImages.first(where: { $0.key == message_id }) {
                        let valueListGroupImages = listGroupImages.value
                        for i in 0..<valueListGroupImages.count {
                            Download().startHTTP(forKey:valueListGroupImages[i].imageId) { (name, progress) in
                                guard progress == 100 else {
                                    return
                                }
                                do {
                                    let secureName = try FileEncryption.shared.writeSecure(filename: valueListGroupImages[i].imageId)?[0]
                                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                                    if let dirPath = paths.first {
                                        let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(valueListGroupImages[i].imageId)
                                        if FileManager.default.fileExists(atPath: imageURL.path) {
                                            let image    = UIImage(contentsOfFile: imageURL.path)
                                            let save: Bool = SecureUserDefaults.shared.value(forKey: "saveToGallery") ?? false
                                            if save {
                                                UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
                                            }
                                        }
                                        else if FileEncryption.shared.isSecureExists(filename: valueListGroupImages[i].imageId) {
                                            if let secureData = try FileEncryption.shared.readSecure(filename: valueListGroupImages[i].imageId) {
                                                let image = UIImage(data: secureData)
                                                let save: Bool = SecureUserDefaults.shared.value(forKey: "saveToGallery") ?? false
                                                if save {
                                                    UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
                                                }
                                            }
                                        }
                                    }
                                }
                                catch {
                                    
                                }
                                DispatchQueue.main.async { [self] in
                                    let section = dataDates.firstIndex(of: dataMessages[index]["chat_date"] as! String)
                                    let row = dataMessages.filter({$0["chat_date"] as! String == dataMessages[index]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == message_id})
                                    if row != nil && section != nil{
                                        tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                    }
                                }
                            }
                        }
                    } else {
                        Download().startHTTP(forKey:dataMessages[index]["image_id"] as! String) { (name, progress) in
                            guard progress == 100 else {
                                return
                            }
                            do {
                                let secureName = try FileEncryption.shared.writeSecure(filename: self.dataMessages[index]["image_id"] as? String)?[0] as! String
                                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                                if let dirPath = paths.first {
                                    let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(self.dataMessages[index]["image_id"] as! String)
                                    if FileManager.default.fileExists(atPath: imageURL.path) {
                                        let image    = UIImage(contentsOfFile: imageURL.path)
                                        let save: Bool = SecureUserDefaults.shared.value(forKey: "saveToGallery") ?? false
                                        if save {
                                            UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
                                        }
                                    }
                                    else if FileEncryption.shared.isSecureExists(filename: secureName) {
                                        if let secureData = try FileEncryption.shared.readSecure(filename: secureName) {
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
                                let section = dataDates.firstIndex(of: dataMessages[index]["chat_date"] as! String)
                                let row = dataMessages.filter({$0["chat_date"] as! String == dataMessages[index]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == message_id})
                                if row != nil && section != nil{
                                    tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                }
                            }
                        }
                    }
                } else if dataMessages[index]["video_id"] as? String != nil && !((dataMessages[index]["video_id"] as? String)!.isEmpty){
                    Download().startHTTP(forKey: dataMessages[index]["video_id"] as! String, isImage: false) { (name, progress) in
                        guard progress == 100 else {
                            return
                        }
                        do {
                            let secureName = try FileEncryption.shared.writeSecure(filename: self.dataMessages[index]["video_id"] as? String)?[0] as! String
                            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                            if let dirPath = paths.first {
                                let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(self.dataMessages[index]["video_id"] as! String)
                                if FileManager.default.fileExists(atPath: videoURL.path) {
                                    let save: Bool = SecureUserDefaults.shared.value(forKey: "saveToGallery") ?? false
                                    if save {
                                        PHPhotoLibrary.shared().performChanges({
                                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                                        }) { saved, error in
                                            
                                        }
                                    }
                                }
                                else if FileEncryption.shared.isSecureExists(filename: secureName) {
                                    if let secureData = try FileEncryption.shared.readSecure(filename: secureName) {
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
                        } catch {
                            
                        }
                        DispatchQueue.main.async { [self] in
                            let section = dataDates.firstIndex(of: dataMessages[index]["chat_date"] as! String)
                            let row = dataMessages.filter({$0["chat_date"] as! String == dataMessages[index]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == message_id})
                            if row != nil && section != nil{
                                tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                            }
                        }
                    }
                }
                else if dataMessages[index]["file_id"] as? String != nil && !((dataMessages[index]["file_id"] as? String)!.isEmpty) {
                    Download().startHTTP(forKey: dataMessages[index]["file_id"] as! String, isImage: false) { (name, progress) in
                        guard progress == 100 else {
                            return
                        }
                        do {
                            try FileEncryption.shared.writeSecure(filename: name)
                        } catch {
                            
                        }
                        DispatchQueue.main.async { [self] in
                            let section = dataDates.firstIndex(of: dataMessages[index]["chat_date"] as! String)
                            let row = dataMessages.filter({$0["chat_date"] as! String == dataMessages[index]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == message_id})
                            if row != nil && section != nil{
                                tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func sendTyping(l_pin: String, isTyping: Bool = false) {
        DispatchQueue.global().async {
            let tmessage = CoreMessage_TMessageBank.getUpdateTypingStatus(p_opposite: l_pin, p_scope: "3", p_status: isTyping ? "3": "4")
            _ = Nexilis.write(message: tmessage)
        }
    }
    
    private func getCounter() {
        Database().database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "SELECT counter FROM MESSAGE_SUMMARY where l_pin='\(dataPerson["f_pin"]!!)'"), c.next() {
                counter = Int(c.int(forColumnIndex: 0))
                c.close()
            }
        })
    }
    
    private func updateCounter(counter: Int) {
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                        "counter" : "\(counter)"
                    ], _where: "l_pin = '\(self.dataPerson["f_pin"]!!)'")
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
        }
    }
    
    private func addButtonScrollToBottom() {
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
        labelCounter.font = UIFont.systemFont(ofSize: 11)
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
    
    private func checkNewMessage(tableView: UITableView) {
//        let indexPathFirst = tableView.indexPathsForVisibleRows?.first
//        if indexPathFirst != nil {
//            let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPathFirst!.section] })
//            if self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPathFirst!.row]["message_id"] as? String }) == 0 && !gettingDataMessage {
//                gettingDataMessage = true
//                addDataMessage()
//            }
//        }
        currentIndexpath = tableView.indexPathsForVisibleRows?.last
        let indexFirst = tableView.indexPathsForVisibleRows?.first
        if indexFirst != nil {
            let dataMessages = dataMessages.filter({ $0["chat_date"] as! String == dataDates[currentIndexpath!.section] })
            if dataMessages.count == 0 || dataMessages.count - 1 < currentIndexpath!.row {
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
            var listData = dataMessages[0...currentIndexpath!.row]
            listData = listData.filter({$0["status"] as? String != "4" && $0["status"] as? String != "8"})
            if listData.count != 0 && !isContactCenter {
                let idMe = User.getMyPin() as String?
                for i in 0...listData.count - 1 {
                    if listData[i]["f_pin"] as? String != idMe {
                        sendReadMessageStatus(chat_id: "", f_pin: dataPerson["f_pin"]!!, message_scope_id: "3", message_id: listData[i]["message_id"] as! String)
                    }
                }
            }
        }
        if counter == 0 && indicatorCounterBSTB.isDescendant(of: self.view) {
            indicatorCounterBSTB.removeConstraints(indicatorCounterBSTB.constraints)
            indicatorCounterBSTB.removeFromSuperview()
        } else if counter != 0 && currentIndexpath != nil {
            let dataFilter = dataMessages.filter({ $0["chat_date"] as! String == dataDates[currentIndexpath!.section] })
            if dataFilter.count == 0 {
                return
            }
            let idx = dataMessages.firstIndex(where: { $0["message_id"] as? String == dataFilter[currentIndexpath!.row]["message_id"] as? String})
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

//EPV
extension EditorPersonal: PreviewAttachmentImageVideoDelegate {
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
            previewImageVC.isAck = self.isAck
            previewImageVC.isConfidential = self.isConfidential
            previewImageVC.isCC = self.isContactCenter
            self.present(previewImageVC, animated: true, completion: nil)
        }
    }
    
    func sendChatFromPreviewImage(message_text: String, attachment_flag: String, image_id: String, video_id: String, thumb_id: String, viewController: UIViewController) {
        sendChat(message_text: message_text, attachment_flag: attachment_flag, image_id: image_id, video_id: video_id, thumb_id: thumb_id, viewController: viewController)
    }
}

//EQL
extension EditorPersonal: UIDocumentPickerDelegate, DocumentPickerDelegate, QLPreviewControllerDataSource {
    public func didSelectDocument(document: Any?) {
        if (document != nil) {
            self.previewItem = (document as! [URL])[0] as NSURL
            let previewController = QLPreviewController()
            let navController = CustomNavigationController(rootViewController: previewController)
            navController.navigationBar.tintColor = .white
            navController.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
            navController.navigationBar.isTranslucent = false
            navController.navigationBar.overrideUserInterfaceStyle = .dark
            navController.navigationBar.barStyle = .black
            let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
            UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
            let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
            navController.navigationBar.titleTextAttributes = textAttributes
            let leftBarButton = navigationQLPreviewDocument(title: "Cancel".localized(), style: .plain, target: self, action: #selector(cancelDocumentPreview))
            let rightBarButton = navigationQLPreviewDocument(title: "Send".localized(), style: .done, target: self, action: #selector(sendDocument))
//            leftBarButton.tintColor = .white
//            rightBarButton.tintColor = .white
            leftBarButton.navigation = navController
            rightBarButton.navigation = navController
//            navController.navigationBar.barTintColor = .mainColor
            navController.navigationBar.isTranslucent = false
            previewController.navigationItem.leftBarButtonItem = leftBarButton
            previewController.navigationItem.rightBarButtonItem = rightBarButton
            previewController.dataSource = self
            previewController.modalPresentationStyle = .pageSheet
            
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    @objc private func cancelDocumentPreview(sender: navigationQLPreviewDocument) {
        sender.navigation.dismiss(animated: true, completion: nil)
    }
    
    @objc private func sendDocument(sender: navigationQLPreviewDocument) {
        sender.navigation.dismiss(animated: true, completion: nil)
        do {
            let dataFile = try Data(contentsOf: self.previewItem! as URL)
            let urlFile = self.previewItem?.absoluteString
            var originaFileName = (urlFile! as NSString).lastPathComponent
            originaFileName = NSString(string: originaFileName).removingPercentEncoding!
            let renamedNameFile = "Qmera_doc_" + "\(Date().currentTimeMillis())_" + originaFileName
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent(renamedNameFile)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    try dataFile.write(to: fileURL)
                    //print("file saved")
                } catch {
                    //print("error saving file:", error)
                }
            }
            sendChat(message_text: "\(originaFileName)|", attachment_flag: "6", file_id: renamedNameFile, viewController: self)
        } catch {
            
        }
    }
    
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.previewItem != nil ? 1 : 0
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.previewItem!
    }
}

//ETV
extension EditorPersonal: UITextViewDelegate {
    public func textViewDidChangeSelection(_ textView: UITextView) {
        let cursorPosition = textView.caretRect(for: self.textFieldSend.selectedTextRange!.start).origin
        let currentLine = Int(cursorPosition.y / self.textFieldSend.font!.lineHeight)
        UIView.animate(withDuration: 0.3) {
            let numberOfLines = textView.textContainer.lineBreakMode == .byWordWrapping ? Int(textView.contentSize.height / textView.font!.lineHeight) - 1 : 1
            if currentLine == 0 && numberOfLines == 1 {
                self.heightTextFieldSend.constant = 40
            } else if self.heightTextFieldSend.constant < 95.0 && currentLine >= 4 {
                self.heightTextFieldSend.constant = 95.0
            } else if currentLine < 4 && numberOfLines < 5 {
                if (self.textFieldSend.text.count > 0 && self.heightTextFieldSend.constant != self.textFieldSend.contentSize.height) {
                    self.heightTextFieldSend.constant = self.textFieldSend.contentSize.height
                }
            }
        }
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        if textView.text.count == 0 {
            isAlwaysHideLinkPreview = false
        }
        if allowTyping {
            allowTyping = false
            if isContactCenter && !fPinContacCenter.isEmpty {
                sendTyping(l_pin: fPinContacCenter, isTyping: true)
            } else {
                sendTyping(l_pin: dataPerson["f_pin"]!!, isTyping: true)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: {
                self.allowTyping = true
            })
        }
        timerCheckLink?.invalidate()
        timerCheckLink = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {_ in
            self.checkLink(fullText: textView.text)
        })
        if textView.text.contains("*") || textView.text.contains("_") || textView.text.contains("^") || textView.text.contains("~") {
            textView.preserveCursorPosition(withChanges: { _ in
                textView.attributedText = textView.text.richText(isEditing: true)
                return .preserveCursor
            })
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
                        let title = data["title"] as! String
                        let description = data["description"] as! String
                        let imageUrl = data["imageUrl"] as? String
                        let link = data["link"] as! String
                        if self.showingLink != text {
                            self.showingLink = text
                            self.deleteLinkPreview()
                            self.buildPreviewLink(imageUrl: imageUrl, title: title, description: description, stringURl: link)
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
                        let title = result.title ?? "No Title"
                        let description = stringURl.contains("google.com") ? "" : result.description
                        let imageUrl = result.icon
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
                            self.buildPreviewLink(imageUrl: imageUrl, title: title, description: description, stringURl: text)
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
        descPreview.font = UIFont.systemFont(ofSize: 12.0)
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
        linkPreview.topAnchor.constraint(equalTo: descPreview.bottomAnchor, constant: 8.0).isActive = true
        linkPreview.trailingAnchor.constraint(equalTo: self.containerLink.trailingAnchor, constant: -80.0).isActive = true
        linkPreview.text = stringURl
        linkPreview.font = UIFont.systemFont(ofSize: 10.0)
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
        if textView.text.isEmpty {
            textView.text = "Send message".localized()
            textView.textColor = UIColor.lightGray
        }
    }
    
    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) && (UIPasteboard.general.image != nil) {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    public override func paste(_ sender: Any?) {
        if UIPasteboard.general.image != nil {
            let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
            previewImageVC.image = UIPasteboard.general.image
            previewImageVC.fromCopy = true
            previewImageVC.currentTextTextField = textFieldSend.text
            previewImageVC.modalPresentationStyle = .custom
            previewImageVC.delegate = self
            previewImageVC.isAck = self.isAck
            previewImageVC.isConfidential = self.isConfidential
            previewImageVC.isCC = self.isContactCenter
            self.present(previewImageVC, animated: true, completion: nil)
        }
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (self.textFieldSend.text.count == 0) {
            return text != "\n"
        }
        return true
    }
}

//EUC
extension EditorPersonal: UIContextMenuInteractionDelegate {
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
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath!.section]})
        var star: UIAction
        if (dataMessages[indexPath!.row]["is_stared"] as! String == "0") {
            star = UIAction(title: "Star".localized(), image: UIImage(systemName: "star.fill"), handler: {(_) in
                if self.removed {
                    return
                }
                DispatchQueue.global().async {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                "is_stared" : 1
                            ], _where: "message_id = '\(dataMessages[indexPath!.row]["message_id"] as! String)'")
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                }
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["is_stared"] = "1"
                }
                self.tableChatView.reloadRows(at: [indexPath!], with: .none)
            })
        } else {
            star = UIAction(title: "Unstar".localized(), image: UIImage(systemName: "star.slash.fill"), handler: {(_) in
                if self.removed {
                    return
                }
                DispatchQueue.global().async {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                "is_stared" : 0
                            ], _where: "message_id = '\(dataMessages[indexPath!.row]["message_id"] as! String)'")
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                }
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["is_stared"] = "0"
                }
                self.tableChatView.reloadRows(at: [indexPath!], with: .none)
            })
        }
        
        let reply = UIAction(title: "Reply".localized(), image: UIImage(systemName: "arrowshape.turn.up.left.fill"), handler: {(_) in
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
        let forward = UIAction(title: "Forward".localized(), image: UIImage(systemName: "arrowshape.turn.up.right.fill"), handler: {(_) in
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
                cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
                if self.dataPerson["f_pin"] != "-999" && !self.isContactCenter {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                if self.isContactCenter || self.fromNotification {
                    self.navigationItem.leftBarButtonItem = nil
                }
                self.changeAppBar()
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = true
                }
                self.addMultipleSelectSession()
                self.tableChatView.reloadData()
            }
        })
        let copy = UIAction(title: "Copy".localized(), image: UIImage(systemName: "doc.on.doc.fill"), handler: {(_) in
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
                cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
                if self.dataPerson["f_pin"] != "-999" && !self.isContactCenter {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                if self.isContactCenter || self.fromNotification {
                    self.navigationItem.leftBarButtonItem = nil
                }
                self.changeAppBar()
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = true
                }
                self.addMultipleSelectSession()
                self.tableChatView.reloadData()
            }
        })
        let edit = UIAction(title: "Edit".localized(), image: UIImage(systemName: "pencil"), handler: {(_) in
            self.showEditMessageAlert(at: indexPath!)
        })
        let info = UIAction(title: "Info".localized(), image: UIImage(systemName: "info.circle.fill"), handler: {(_) in
            if self.removed {
                return
            }
            let messageInfoVC = MessageInfo()
            messageInfoVC.data = dataMessages[indexPath!.row]
            messageInfoVC.dataPerson = self.dataPerson
            self.navigationController?.pushViewController(messageInfoVC, animated: true)
        })
        let delete = UIAction(title: "Delete".localized(), image: UIImage(systemName: "trash.fill"), attributes: .destructive, handler: {(_) in
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
                cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
                if self.dataPerson["f_pin"] != "-999" && !self.isContactCenter {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                if self.isContactCenter || self.fromNotification {
                    self.navigationItem.leftBarButtonItem = nil
                }
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
            let messageId = dataMessages[indexPath!.row][TypeDataMessage.message_id] as! String
            let status = dataMessages[indexPath!.row][TypeDataMessage.status] as! String
            
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
                    let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                    let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
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
                                                               l_pin: dataMessages[indexPath!.row][TypeDataMessage.l_pin] as! String,
                                                               message_scope_id: dataMessages[indexPath!.row][TypeDataMessage.message_scope_id] as! String,
                                                               status: "1",
                                                               message_text: dataMessages[indexPath!.row][TypeDataMessage.message_text] as! String,
                                                               credential: dataMessages[indexPath!.row][TypeDataMessage.credential] as! String,
                                                               attachment_flag: dataMessages[indexPath!.row][TypeDataMessage.attachment_flag] as! String,
                                                               ex_blog_id: dataMessages[indexPath!.row][TypeDataMessage.blog_id] as! String,
                                                               message_large_text: "",
                                                               ex_format: "",
                                                               image_id: dataMessages[indexPath!.row][TypeDataMessage.image_id] as! String,
                                                               audio_id: dataMessages[indexPath!.row][TypeDataMessage.audio_id] as! String,
                                                               video_id: dataMessages[indexPath!.row][TypeDataMessage.video_id] as! String,
                                                               file_id: dataMessages[indexPath!.row][TypeDataMessage.file_id] as! String,
                                                               thumb_id: dataMessages[indexPath!.row][TypeDataMessage.thumb_id] as! String,
                                                               reff_id: dataMessages[indexPath!.row][TypeDataMessage.reff_id] as! String,
                                                               read_receipts: dataMessages[indexPath!.row][TypeDataMessage.read_receipts] as! String,
                                                               chat_id: dataMessages[indexPath!.row][TypeDataMessage.chat_id] as! String,
                                                               is_call_center: dataMessages[indexPath!.row][TypeDataMessage.is_call_center] as! String,
                                                               call_center_id: dataMessages[indexPath!.row][TypeDataMessage.call_center_id] as! String,
                                                               opposite_pin: dataMessages[indexPath!.row][TypeDataMessage.opposite_pin] as! String)
            Nexilis.addQueueMessage(message: message)
        })
        
        var children: [UIMenuElement] = [star, reply, forward, copy, delete]
//        let copyOption = self.copyOption(indexPath: indexPath!)
        let idMe = User.getMyPin() as String?
        print("LOHE \(isContactCenter)")
        if dataMessages[indexPath!.row]["status"] as! String == "0" {
            children = [resend, delete]
        } else if isContactCenter {
            if dataMessages[indexPath!.row]["attachment_flag"] as! String == "11" {
                children = [reply]
            }
            else {
                children = [reply, copy]
            }
        } else if (dataMessages[indexPath!.row]["lock"] != nil && dataMessages[indexPath!.row]["lock"] as! String == "1") || dataMessages[indexPath!.row]["message_scope_id"] as! String == "18" || dataPerson["f_pin"] == "-999" || dataMessages[indexPath!.row]["credential"] as! String == "1" {
            children = [delete]
        } else if (groupImages[dataMessages[indexPath!.row]["message_id"] as! String] != nil) {
            forward.title = "Forward All".localized()
            delete.title = "Delete All".localized()
            children = [forward, delete]
        } else if blocking == "1" || blocking == "-1" {
            children = [star, forward, copy ,delete]
            if !(dataMessages[indexPath!.row]["image_id"] as! String).isEmpty || !(dataMessages[indexPath!.row]["video_id"] as! String).isEmpty {
                children = [star, forward ,delete]
            }
            if (dataMessages[indexPath!.row]["f_pin"] as! String) == idMe {
                children.insert(info, at: children.count - 1)
            }
        }
        else if !(dataMessages[indexPath!.row]["image_id"] as! String).isEmpty || !(dataMessages[indexPath!.row]["video_id"] as! String).isEmpty || !(dataMessages[indexPath!.row]["file_id"] as! String).isEmpty {
            children = [star, reply, forward ,delete]
            if (dataMessages[indexPath!.row]["f_pin"] as! String) == idMe {
                children.insert(info, at: children.count - 1)
            }
        } else if dataMessages[indexPath!.row]["attachment_flag"] as! String == "11" {
            children = [reply, delete]
            if (dataMessages[indexPath!.row]["f_pin"] as! String) == idMe {
                children.insert(info, at: children.count - 1)
            }
        } else {
            if (dataMessages[indexPath!.row]["f_pin"] as! String) == idMe {
                children.insert(info, at: children.count - 1)
            }
//            if !(dataMessages[indexPath!.row][TypeDataMessage.message_text] as! String).isEmpty && (dataMessages[indexPath!.row]["f_pin"] as! String) == idMe {
//                children.insert(edit, at: children.count - 1)
//            }
        }
        if isEditAction {
            return UIContextMenuConfiguration(identifier: nil,
                                              previewProvider: {
                self.textFieldSend.becomeFirstResponder()
                return nil
            }) { _ in
                return nil
            }
        }
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { _ in
            UIMenu(title: "", children: children)
        }
    }
    
    func showEditMessageAlert(at indexPath: IndexPath) {
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath.section]})
        let oldText = dataMessages[indexPath.row][TypeDataMessage.message_text] as! String
        let alertController = UIAlertController(title: "Edit".localized(), message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = oldText
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            if let textField = alertController.textFields?.first, let newText = textField.text {
                if newText.trimmingCharacters(in: .whitespacesAndNewlines) != oldText {
                    let lastEdited = 1 + ((dataMessages[indexPath.row][TypeDataMessage.last_edit] as? Int64) ?? 0)
                    let message = CoreMessage_TMessageBank.editMessage(message_id: dataMessages[indexPath.row][TypeDataMessage.message_id] as! String, l_pin: dataMessages[indexPath.row][TypeDataMessage.l_pin] as! String, message_scope_id: dataMessages[indexPath.row][TypeDataMessage.message_scope_id] as! String, status: "1", message_text: newText, credential: dataMessages[indexPath.row][TypeDataMessage.credential] as! String, attachment_flag: dataMessages[indexPath.row][TypeDataMessage.attachment_flag] as! String, ex_blog_id: dataMessages[indexPath.row][TypeDataMessage.blog_id] as! String, message_large_text: "", ex_format: "", image_id: dataMessages[indexPath.row][TypeDataMessage.image_id] as! String, audio_id: dataMessages[indexPath.row][TypeDataMessage.audio_id] as! String, video_id: dataMessages[indexPath.row][TypeDataMessage.video_id] as! String, file_id: dataMessages[indexPath.row][TypeDataMessage.file_id] as! String, thumb_id: dataMessages[indexPath.row][TypeDataMessage.thumb_id] as! String, reff_id: dataMessages[indexPath.row][TypeDataMessage.reff_id] as! String, read_receipts: dataMessages[indexPath.row][TypeDataMessage.read_receipts] as! String, chat_id: dataMessages[indexPath.row][TypeDataMessage.chat_id] as! String, is_call_center: dataMessages[indexPath.row][TypeDataMessage.is_call_center] as! String, call_center_id: dataMessages[indexPath.row][TypeDataMessage.call_center_id] as! String, opposite_pin: dataMessages[indexPath.row][TypeDataMessage.opposite_pin] as! String, last_edit: lastEdited)
                    Nexilis.addQueueMessage(message: message, isEditMessage: true)
                    DispatchQueue.global().async {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                    "message_text" : newText,
                                    "last_edited" : lastEdited
                                ], _where: "message_id = '\(dataMessages[indexPath.row]["message_id"] as! String)'")
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                    }
                    let idx = self?.dataMessages.firstIndex(where: { $0[TypeDataMessage.message_id] as? String == dataMessages[indexPath.row][TypeDataMessage.message_id] as? String})
                    if idx != nil{
                        self?.dataMessages[idx!][TypeDataMessage.message_text] = newText
                        self?.dataMessages[idx!][TypeDataMessage.last_edit] = lastEdited
                        self?.tableChatView.reloadRows(at: [indexPath], with: .none)
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
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
            let data = self.dataMessages.filter({ $0["isSelected"] as? Bool == true })
            for i in 0..<data.count {
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == data[i]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = false
                }
            }
            self.tableChatView.reloadData()
            self.setRightButtonItem()
            self.changeAppBar()
            if self.isContactCenter || self.fromNotification {
                let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(self.didTapExit))
                self.navigationItem.leftBarButtonItem = backButton
            }
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
            let countSelected = dataMessages.filter({ $0["isSelected"] as? Bool == true }).count
            title.text = "\(countSelected) " + "Selected".localized()
            title.textColor = .mainColor
            title.font = UIFont.systemFont(ofSize: 15.0).bold
            
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
                if countSelected == 0 {
                    button.tintColor = .gray
                } else {
                    button.tintColor = .mainColor
                }
            } else if forwardSession {
                button.image = UIImage(systemName: "arrowshape.turn.up.right")
                if countSelected == 0 {
                    button.tintColor = .gray
                } else {
                    button.tintColor = .mainColor
                }
            } else if deleteSession {
                button.image = UIImage(systemName: "trash")
                if countSelected == 0 {
                    button.tintColor = .gray
                } else {
                    button.tintColor = .red
                }
            }
            let buttonGesture = UITapGestureRecognizer(target: self, action: #selector(sessionAction))
            button.isUserInteractionEnabled = true
            button.addGestureRecognizer(buttonGesture)
            
            let selectedMessage = dataMessages.filter({ $0["isSelected"] as? Bool == true })
            if selectedMessage.count > 0 {
                for i in 0..<selectedMessage.count {
                    if let isGroupingImages = groupImages[selectedMessage[i]["message_id"] as! String] {
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
            let dataMessages = self.dataMessages.filter({ $0["isSelected"] as? Bool == true })
            let countSelected = dataMessages.count
            if countSelected == 0 {
                return
            }
            var text = ""
            for i in 0..<countSelected {
                let stringDate = (dataMessages[i]["server_date"] as! String)
                let date = Date(milliseconds: Int64(stringDate)!)
                let formatterDate = DateFormatter()
                let formatterTime = DateFormatter()
                formatterDate.dateFormat = "dd/MM/yy"
                formatterDate.locale = NSLocale(localeIdentifier: "id") as Locale?
                formatterTime.dateFormat = "HH:mm"
                formatterTime.locale = NSLocale(localeIdentifier: "id") as Locale?
                let dataProfile = getDataProfile(message_id: dataMessages[i]["message_id"] as! String)
                if text.isEmpty {
                    text = "*[\(formatterDate.string(from: date as Date)) \(formatterTime.string(from: date as Date))] \(dataProfile["name"]!):*\n\(dataMessages[i]["message_text"] as! String)"
                } else {
                    text = text + "\n\n*[\(formatterDate.string(from: date as Date)) \(formatterTime.string(from: date as Date))] \(dataProfile["name"]!):*\n\(dataMessages[i]["message_text"] as! String)"
                }
            }
            text = text + "\n\n\nchat " + "Powered by Nexilis".localized()
            DispatchQueue.main.async {
                UIPasteboard.general.string = text
                self.showToast(message: "Text coppied to clipboard".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
            }
            cancelAction()
        } else if forwardSession {
            var dataMessages = self.dataMessages.filter({ $0["isSelected"] as! Bool == true })
            let countSelected = dataMessages.count
            if countSelected == 0 {
                return
            }
            for i in 0..<countSelected {
                if groupImages[dataMessages[i]["message_id"] as! String] != nil {
                    var tempData = dataMessages
                    tempData.remove(at: 0)
                    let dataMessageInGrouping = (groupImages[dataMessages[i]["message_id"] as! String]!).map({ $0.dataMessage })
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
            contactChatNav.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
            if let controller = contactChatNav.viewControllers.first as? ContactChatViewController {
                controller.isChooser = { [weak self] scope, pin in
                    if scope == "3" {
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
            var countSelected = dataMessages.count
            if countSelected == 0 {
                return
            }
            for i in 0..<countSelected {
                if let isGroupingImages = groupImages[dataMessages[i]["message_id"] as! String] {
                    countSelected += (isGroupingImages.count - 1)
                }
            }
            let alertController = LibAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            if let action = self.actionDelete(for: "me", title: "Delete".localized() + " \(countSelected) " + "For Me".localized(), dataMessages: dataMessages) {
                alertController.addAction(action)
            }
            let idMe = User.getMyPin() as String?
            let dataFilterFpin = dataMessages.filter({ $0["l_pin"] as? String == idMe})
            let dataFilterLock = dataMessages.filter({ $0["lock"] as? String == "1" || $0["lock"] as? String == "2" })
//            let statusDataRead = dataMessages.filter({ Int($0["status"] as! String)! >= 4})
            let statusFailed = dataMessages.filter({ Int($0["status"] as! String)! == 0})
            if dataFilterFpin.count == 0 && dataFilterLock.count == 0 && statusFailed.count == 0 {
                if let action = self.actionDelete(for: "everyone", title: "Delete".localized() + " \(countSelected) " + "For Everyone".localized(), dataMessages: dataMessages) {
                    alertController.addAction(action)
                }
            }
            alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
            self.present(alertController, animated: true)
        }
    }
    
    private func getDataProfile(message_id: String) -> [String: String]{
        var data: [String: String] = [:]
        Database().database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "select f_display_name from MESSAGE where message_id = '\(message_id)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0)!
                c.close()
            } else {
                data["name"] = "Unknown".localized()
                data["image_id"] = ""
            }
        })
        return data
    }
    
    private func deleteMessage(l_pin: String, message_id: String, scope: String, type: String, chat: String) {
        let tmessage = CoreMessage_TMessageBank.deleteMessage(l_pin: l_pin, messageId: message_id, scope: scope, type: type, chat: chat)
        Nexilis.deleteQueueMessage(message: tmessage)
    }
    
    private func queryMessageReply(message_id: String) -> [String: Any?] {
        var dataQuery: [String: Any] = [:]
        Database().database?.inTransaction({ fmdb, rollback in
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
        if (dataMessages[indexPath.row]["message_text"] as! String).isEmpty {
            ratingButtonTitles = ["Image".localized()]
        }
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath.section]})
        let copyActions = ratingButtonTitles
            .enumerated()
            .map { index, title in
                return UIAction(
                    title: title,
                    identifier: nil,
                    handler: {(_) in
                        if (dataMessages[indexPath.row]["message_text"] as! String).isEmpty {
                            DispatchQueue.main.async {
                                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                                if let dirPath = paths.first {
                                    let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(dataMessages[indexPath.row]["image_id"] as! String)
                                    if FileManager.default.fileExists(atPath: imageURL.path) {
                                        let image    = UIImage(contentsOfFile: imageURL.path)
                                        UIPasteboard.general.image = image
                                        self.showToast(message: "Image coppied to clipboard".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                                    } else if FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
                                        do {
                                            if let imageData = try FileEncryption.shared.readSecure(filename: imageURL.lastPathComponent) {
                                                let image = UIImage(data: imageData)
                                                UIPasteboard.general.image = image
                                                self.showToast(message: "Image coppied to clipboard".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
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
                                self.showToast(message: "Text coppied to clipboard".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                            }
                        } else {
                            DispatchQueue.main.async {
                                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                                if let dirPath = paths.first {
                                    let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(dataMessages[indexPath.row]["image_id"] as! String)
                                    if FileManager.default.fileExists(atPath: imageURL.path) {
                                        let image    = UIImage(contentsOfFile: imageURL.path)
                                        UIPasteboard.general.image = image
                                        self.showToast(message: "Image coppied to clipboard".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                                    } else if FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
                                        do {
                                            if let imageData = try FileEncryption.shared.readSecure(filename: imageURL.lastPathComponent) {
                                                let image = UIImage(data: imageData)
                                                UIPasteboard.general.image = image
                                                self.showToast(message: "Image coppied to clipboard".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
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
                    if let groupingImages = groupImages[dataMessages[i]["message_id"] as! String] {
                        for i in 0..<groupingImages.count {
                            self.deleteMessage(l_pin: groupingImages[i].lPin, message_id: groupingImages[i].messageId, scope: "3", type: "1", chat: "")
                            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == groupingImages[i].messageId })
                            if idx != nil {
                                self.dataMessages.remove(at: idx!)
                                if (idx == self.dataMessages.count - 1) {
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                                }
                                for i in 0..<dataDates.count {
                                    if self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[i] }).count == 0 {
                                        dataDates.remove(at: i)
                                    }
                                }
                            }
                        }
                        self.groupImages.removeValue(forKey: groupingImages[0].messageId)
                    } else {
                        self.deleteMessage(l_pin: dataMessages[i]["l_pin"] as! String, message_id: dataMessages[i]["message_id"] as! String, scope: "3", type: "1", chat: "")
                        let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[i]["message_id"] as? String})
                        if idx != nil {
                            self.dataMessages.remove(at: idx!)
                            if (idx == self.dataMessages.count - 1) {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                            }
                            for i in 0..<dataDates.count {
                                if self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[i] }).count == 0 {
                                    dataDates.remove(at: i)
                                }
                            }
                        }
                    }
                } else {
                    if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    } else {
                        if let groupingImages = groupImages[dataMessages[i]["message_id"] as! String] {
                            for i in 0..<groupingImages.count {
                                self.deleteMessage(l_pin: groupingImages[i].lPin, message_id: groupingImages[i].messageId, scope: "3", type: "2", chat: "")
                                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == groupingImages[i].messageId})
                                if idx != nil {
                                    self.dataMessages[idx!]["lock"] = "1"
                                    self.dataMessages[idx!]["attachment_flag"] = "0"
                                    self.dataMessages[idx!]["reff_id"] = ""
                                }
                            }
                            if let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == groupingImages[0].messageId}) {
                                var dataMessageInGrouping = (groupImages[dataMessages[i]["message_id"] as! String]!).map({ $0.dataMessage })
                                dataMessageInGrouping.remove(at: 0)
                                self.dataMessages.insert(contentsOf: dataMessageInGrouping, at: idx+1)
                                self.groupImages.removeValue(forKey: groupingImages[0].messageId)
                            }
                        } else {
                            self.deleteMessage(l_pin: dataMessages[i]["l_pin"] as! String, message_id: dataMessages[i]["message_id"] as! String, scope: "3", type: "2", chat: "")
                            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[i]["message_id"] as? String})
                            if idx != nil {
                                self.dataMessages[idx!]["lock"] = "1"
                                self.dataMessages[idx!]["attachment_flag"] = "0"
                                self.dataMessages[idx!]["reff_id"] = ""
                            }
                        }
                    }
                }
                if self.listTimerCredential[dataMessages[i]["message_id"] as! String] != nil {
                    self.listTimerCredential.removeValue(forKey: dataMessages[i]["message_id"] as! String)
                    self.timerCredential[dataMessages[i]["message_id"] as! String]?.invalidate()
                    self.timerCredential.removeValue(forKey: dataMessages[i]["message_id"] as! String)
                }
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
            cancelAction()
        }
    }
    
    private func updateProfile() {
        let idMe = User.getMyPin() as String?
        DispatchQueue.global().async {
            let message = CoreMessage_TMessageBank.getBatchBuddiesInfos(p_f_pin: idMe!, last_update: 0)
            let _ = Nexilis.write(message: message)
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }
    
    @objc func deleteReplyView() {
        if self.containerPreviewReply.isDescendant(of: self.viewTextfield) {
            self.containerPreviewReply.subviews.forEach { $0.removeFromSuperview() }
            self.containerPreviewReply.removeConstraints(self.containerPreviewReply.constraints)
            self.containerPreviewReply.removeFromSuperview()
            
            self.reffId = nil
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                self.constraintTopTextField.constant = self.constraintTopTextField.constant - 50
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

//ECL
extension EditorPersonal: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 76
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellSticker", for: indexPath)
        if (cell.contentView.subviews.count > 0) {
            cell.contentView.subviews.forEach({ $0.removeFromSuperview() })
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
        imageSticker.image = UIImage(named: stickers[indexPath.row], in: Bundle.resourceBundle(for: Nexilis.self), with: nil) //resourcesMediaBundle
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        sendChat(message_text: "sticker/\(stickers[indexPath.row])", attachment_flag: "11", viewController: self)
        constraintBottomAttachment.constant = 0.0
        self.viewSticker.removeConstraints(self.viewSticker.constraints)
        self.viewSticker.removeFromSuperview()
    }
}

//ETB
extension EditorPersonal: UITableViewDelegate, UITableViewDataSource {
//    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        checkNewMessage(tableView: tableView)
//    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if self.tableChatView.alpha != 1.0 {
            UIView.animate(withDuration: 0.5, animations: {
                self.tableChatView.alpha = 1.0
            })
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        lastY = scrollView.contentOffset.y
        DispatchQueue.main.async { [self] in
            checkNewMessage(tableView: self.tableChatView)
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isContactCenter && indexPath.row == 0 && isRequestContactCenter {
            return
        }
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath.section] })
        if copySession || forwardSession || deleteSession {
            if (dataMessages[indexPath.row]["attachment_flag"] as! String != "0" || dataMessages[indexPath.row]["lock"] as? String == "1") && !forwardSession && !deleteSession {
                return
            }
            
            if !(dataMessages[indexPath.row]["image_id"] as! String).isEmpty || !(dataMessages[indexPath.row]["video_id"] as! String).isEmpty || !(dataMessages[indexPath.row]["file_id"] as! String).isEmpty {
                var file = dataMessages[indexPath.row]["image_id"] as! String
                if file.isEmpty {
                    file = dataMessages[indexPath.row]["video_id"] as! String
                    if file.isEmpty {
                        file = dataMessages[indexPath.row]["file_id"] as! String
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
            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath.row]["message_id"] as? String})
            if idx != nil {
                self.dataMessages[idx!]["isSelected"] = !(self.dataMessages[idx!]["isSelected"] as! Bool)
                self.tableChatView.reloadRows(at: [indexPath], with: .none)
            }
            containerMultpileSelectSession.subviews.forEach({ $0.removeFromSuperview() })
            addSubviewMultipleSession()
            return
        }
        let message = dataMessages[indexPath.row]
        if let attachmentFlag = message["attachment_flag"], let attachmentFlag = attachmentFlag as? String {
            if attachmentFlag == "27" || attachmentFlag == "26" {
                let streamingController = (attachmentFlag == "27") ? QmeraCreateStreamingViewController() : CreateSeminarViewController()
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
                        if json["by"] as? String != User.getMyPin() as String? {
                            switch(attachmentFlag){
                                case "27":
                                    (streamingController as! QmeraCreateStreamingViewController).isJoin = true
                                default:
                                    (streamingController as! CreateSeminarViewController).isJoin = true
                            }
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
            } else if  message["message_scope_id"] as? String == "18" {
                let formView = FormEditor()
                let messageText =  message["message_text"] as! String
                formView.jsonData = messageText
                formView.dataMessage = message
                formView.dataPerson = self.dataPerson
                formView.modalPresentationStyle = .custom
                formView.modalTransitionStyle = .crossDissolve
                formView.view.backgroundColor = .black.withAlphaComponent(0.2)
                self.present(formView, animated: true, completion: nil)
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let dateView = UIView()
        containerView.addSubview(dateView)
        dateView.translatesAutoresizingMaskIntoConstraints = false
        var topAnchor = dateView.topAnchor.constraint(equalTo: containerView.topAnchor)
        topAnchor = dateView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10.0)
        NSLayoutConstraint.activate([
            topAnchor,
            dateView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            dateView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            dateView.heightAnchor.constraint(equalToConstant: 30),
            dateView.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        dateView.backgroundColor = .orangeColor
        dateView.layer.cornerRadius = 15.0
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
        labelDate.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        labelDate.text = dataDates[section]
        if listViewOnSection.count == 0 || listViewOnSection.count - 1 < section {
            listViewOnSection.append(containerView)
        } else {
            listViewOnSection.remove(at: section)
            listViewOnSection.insert(containerView, at: section)
        }
        return containerView
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let idMe = User.getMyPin() as String?
        let dataMessages = dataMessages.filter({$0["chat_date"] as! String == dataDates[indexPath.section]})
        let profileMessage = UIImageView()
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellEditorPersonal", for: indexPath as IndexPath)
        cell.contentView.subviews.forEach({ $0.removeFromSuperview() })
        
        if isContactCenter && isRequestContactCenter && dataMessages[indexPath.row]["category_cc"] != nil {
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            
            if dataMessages[indexPath.row]["category_cc"] is [CategoryCC] {
                let category_cc = dataMessages[indexPath.row]["category_cc"] as! [CategoryCC]
                profileMessage.frame.size = CGSize(width: 35, height: 35)
                cell.contentView.addSubview(profileMessage)
                profileMessage.translatesAutoresizingMaskIntoConstraints = false
                profileMessage.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5).isActive = true
                profileMessage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15).isActive = true
                profileMessage.heightAnchor.constraint(equalToConstant: 37).isActive = true
                profileMessage.widthAnchor.constraint(equalToConstant: 35).isActive = true
                profileMessage.circle()
                profileMessage.clipsToBounds = true
                profileMessage.backgroundColor = .lightGray
                profileMessage.image = UIImage(systemName: "person")
                profileMessage.tintColor = .white
                profileMessage.contentMode = .scaleAspectFit
                getImage(name: dataPerson["picture"]!!, placeholderImage: UIImage(systemName: "person.circle.fill")!) { result, isDownloaded, image in
                    profileMessage.image = image
                }
                profileMessage.contentMode = .scaleAspectFill
                
                
                let containerMessage = UIView()
                cell.contentView.addSubview(containerMessage)
                containerMessage.translatesAutoresizingMaskIntoConstraints = false
                containerMessage.topAnchor.constraint(equalTo: profileMessage.bottomAnchor).isActive = true
                containerMessage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 5).isActive = true
                containerMessage.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -60).isActive = true
                containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
//                containerMessage.backgroundColor = .grayColor
//                containerMessage.layer.cornerRadius = 10.0
//                containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
//                containerMessage.clipsToBounds = true
                
//                let timeMessage = UILabel()
//                cell.contentView.addSubview(timeMessage)
//                timeMessage.translatesAutoresizingMaskIntoConstraints = false
//                timeMessage.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: 8).isActive = true
                
                let messageText = UILabel()
                containerMessage.addSubview(messageText)
                messageText.translatesAutoresizingMaskIntoConstraints = false
                messageText.numberOfLines = 0
                messageText.lineBreakMode = .byWordWrapping
                containerMessage.addSubview(messageText)
                messageText.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 5).isActive = true
                messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                messageText.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: -5).isActive = true
                messageText.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                if category_cc[0].id.contains("level0_") || dataMessages[indexPath.row]["attachment_flag"] != nil && dataMessages[indexPath.row]["attachment_flag"] as! String == "503" {
                    messageText.text = "Welcome to".localized() + " " + dataPerson["name"]!! + " " + "Contact Center".localized()
                     + "\n" + "Please choose your desired communication method...".localized()
                } else if category_cc[0].id.contains("level1_") {
                    messageText.text = "Please select your Consultation Topic:".localized()
                } else if !category_cc[0].id.contains("level1_") && dataMessages[indexPath.row]["attachment_flag"] == nil {
                    messageText.text = "Please select the type of topic that you chosen".localized()
                } else if dataMessages[indexPath.row]["attachment_flag"] != nil && dataMessages[indexPath.row]["attachment_flag"] as! String == "502" {
                    messageText.text = "Please select the information option:".localized()
                } else {
                    messageText.text = "Sorry, currently all our representatives are busy helping other customers. Do you want us to get back to you as soon as one of them is available?".localized()
                }
                messageText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
                messageText.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
                
//                let date = Date()
//                let formatter = DateFormatter()
//                formatter.dateFormat = "HH:mm"
//                formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
//                timeMessage.text = formatter.string(from: date as Date)
//                timeMessage.font = UIFont.systemFont(ofSize: 10, weight: .medium)
//                timeMessage.textColor = .lightGray
                
                let containerButton = UIView()
                cell.contentView.addSubview(containerButton)
                containerButton.translatesAutoresizingMaskIntoConstraints = false
                containerButton.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
                containerButton.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -5).isActive = true
                containerButton.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15).isActive = true
                containerButton.widthAnchor.constraint(equalToConstant: self.view!.frame.size.width * 0.9).isActive = true
                containerButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 55).isActive = true
                containerButton.backgroundColor = .clear
//                timeMessage.bottomAnchor.constraint(equalTo:containerButton.topAnchor, constant: -5).isActive = true
                
                
                for i in 0..<category_cc.count {
                    let buttonChat = UIButton(type: .custom)
                    containerButton.addSubview(buttonChat)
                    buttonChat.translatesAutoresizingMaskIntoConstraints = false
                    buttonChat.widthAnchor.constraint(equalToConstant: self.view!.frame.size.width * 0.9 / 2 - 5).isActive = true
                    buttonChat.heightAnchor.constraint(greaterThanOrEqualToConstant: 55).isActive = true
                    if i % 2 == 0 {
                        if i / 2 + 1 == 1 {
                            buttonChat.topAnchor.constraint(equalTo: containerButton.topAnchor, constant: 5).isActive = true
                        } else {
                            var constantTop = (i / 2 - 1) * 50
                            if constantTop == 0 {
                                constantTop = 55
                            } else {
                                constantTop = constantTop + 55
                            }
                            buttonChat.topAnchor.constraint(equalTo: containerButton.topAnchor, constant: CGFloat(constantTop)).isActive = true
                        }
                        if i == category_cc.count - 1 {
                            buttonChat.bottomAnchor.constraint(equalTo: containerButton.bottomAnchor, constant: -5).isActive = true
                        }
                        buttonChat.leadingAnchor.constraint(equalTo: containerButton.leadingAnchor, constant: 5).isActive = true
                    } else {
                        let newi = i - 1
                        if newi / 2 + 1 == 1 {
                            buttonChat.topAnchor.constraint(equalTo: containerButton.topAnchor, constant: 5).isActive = true
                        } else {
                            var constantTop = (newi / 2 - 1) * 50
                            if constantTop == 0 {
                                constantTop = 55
                            } else {
                                constantTop = constantTop + 55
                            }
                            buttonChat.topAnchor.constraint(equalTo: containerButton.topAnchor, constant: CGFloat(constantTop)).isActive = true
                        }
                        if i == category_cc.count - 1 {
                            buttonChat.bottomAnchor.constraint(equalTo: containerButton.bottomAnchor, constant: -5).isActive = true
                        }
                        buttonChat.trailingAnchor.constraint(equalTo: containerButton.trailingAnchor, constant: -5).isActive = true
                    }
                    if category_cc[i].isActive  {
                        buttonChat.backgroundColor = .orangeBNI
                    }
                    var nameImage = "pb_cc_bg_messaging"
                    if i == 1 {
                        nameImage = "pb_cc_bg_sms"
                    } else if i == 2 {
                        nameImage = "pb_cc_bg_voip"
                    } else if i == 3 {
                        nameImage = "pb_cc_bg_email"
                    } else if i == 4 {
                        nameImage = "pb_cc_bg_videocall"
                    } else if i == 5 {
                        nameImage = "pb_cc_bg_gsmcall"
                    } else if i == 6 {
                        nameImage = "pb_cc_bg_gptchatbot"
                    } else if i == 7 {
                        nameImage = "pb_cc_bg_whatsapp"
                    }
                    buttonChat.setImage(resizeImage(image: UIImage(named: nameImage, in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: self.view!.frame.size.width * 0.9 / 2 - 5, height: 55)), for: .normal)
//                    buttonChat.setTitle(category_cc[i].service_name.localized(), for: .normal)
//                    buttonChat.setTitleColor(.black, for: .normal)
//                    buttonChat.setImage(resizeImage(image: UIImage(named: "pb_gpt_bot", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)), for: .normal)
//                    buttonChat.contentHorizontalAlignment = .left
//                    buttonChat.imageEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0) // Adjust left inset for the image
//                    buttonChat.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0) // Adjust left inset for the title
//                    buttonChat.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
//                    buttonChat.titleLabel?.numberOfLines = 0
//                    buttonChat.layer.borderWidth = 2
//                    buttonChat.layer.borderColor = UIColor.white.cgColor
//                    buttonChat.backgroundColor = .grayColor
//                    buttonChat.layer.cornerRadius = 8.0
//                    buttonChat.clipsToBounds = true
                    
                    buttonChat.restorationIdentifier = "\(category_cc[i].id),\(category_cc[i].service_id)"
                    if dataMessages[indexPath.row]["attachment_flag"] != nil {
                        buttonChat.tag = Int(dataMessages[indexPath.row]["attachment_flag"] as! String)!
                    }
                    buttonChat.addTarget(self, action: #selector(ccAction(sender:)), for: .touchUpInside)
                }
            } else {
                let messageWait = UILabel()
                cell.contentView.addSubview(messageWait)
                messageWait.translatesAutoresizingMaskIntoConstraints = false
                messageWait.topAnchor.constraint(equalTo: cell.contentView.topAnchor).isActive = true
                messageWait.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor).isActive = true
                messageWait.leftAnchor.constraint(equalTo: cell.contentView.leftAnchor, constant: 10).isActive = true
                messageWait.rightAnchor.constraint(equalTo: cell.contentView.rightAnchor, constant: -10).isActive = true
                messageWait.text = dataMessages[indexPath.row]["category_cc"] as? String ?? dataMessages[indexPath.row]["message_text"] as? String ?? ""
                messageWait.numberOfLines = 0
                messageWait.font = UIFont.systemFont(ofSize: 12)
                messageWait.textColor = .gray
                messageWait.textAlignment = .center
            }
            
            return cell
        }
        
        let messageIdChat = (dataMessages[indexPath.row]["message_id"] as? String) ?? ""
        let thumbChat = (dataMessages[indexPath.row]["thumb_id"] as? String) ?? ""
        let imageChat = (dataMessages[indexPath.row]["image_id"] as? String) ?? ""
        let videoChat = (dataMessages[indexPath.row]["video_id"] as? String) ?? ""
        let fileChat = (dataMessages[indexPath.row]["file_id"] as? String) ?? ""
        let reffChat = (dataMessages[indexPath.row]["reff_id"] as? String) ?? ""
        let dataTimer = listTimerCredential[(dataMessages[indexPath.row]["message_id"] as! String)]
        
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        let nameSender = UILabel()
        
        if isContactCenter {
            profileMessage.frame.size = CGSize(width: 35, height: 35)
            cell.contentView.addSubview(profileMessage)
            profileMessage.translatesAutoresizingMaskIntoConstraints = false
            profileMessage.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5).isActive = true
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                profileMessage.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -15).isActive = true
            } else {
                if copySession || forwardSession || deleteSession {
                    profileMessage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 50).isActive = true
                } else {
                    profileMessage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15).isActive = true
                }
            }
            profileMessage.heightAnchor.constraint(equalToConstant: 37).isActive = true
            profileMessage.widthAnchor.constraint(equalToConstant: 35).isActive = true
            profileMessage.circle()
            profileMessage.clipsToBounds = true
            profileMessage.backgroundColor = .lightGray
            profileMessage.image = UIImage(systemName: "person")
            profileMessage.tintColor = .white
            profileMessage.contentMode = .scaleAspectFit
            let user = User.getData(pin: dataMessages[indexPath.row]["f_pin"] as? String)
            getImage(name: user?.thumb ?? "", placeholderImage: UIImage(systemName: "person.circle.fill")!, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                profileMessage.image = image
            }
            profileMessage.contentMode = .scaleAspectFill
            
            cell.contentView.addSubview(nameSender)
            nameSender.translatesAutoresizingMaskIntoConstraints = false
            if markerCounter != nil && dataMessages[indexPath.row]["message_id"] as? String == markerCounter {
                nameSender.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 35).isActive = true
            } else {
                nameSender.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5).isActive = true
            }
            nameSender.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight(800))
            nameSender.text = user?.fullName ?? ""
            nameSender.textAlignment = .right
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                nameSender.trailingAnchor.constraint(equalTo:profileMessage.leadingAnchor, constant: -5).isActive = true
                nameSender.textColor = .systemBlue
            } else {
                nameSender.leadingAnchor.constraint(equalTo:profileMessage.trailingAnchor, constant: 5).isActive = true
                nameSender.textColor = .orangeColor
            }
        }
        
        let containerMessage = UIView()
        cell.contentView.addSubview(containerMessage)
        containerMessage.translatesAutoresizingMaskIntoConstraints = false
        
        let timeMessage = UILabel()
        cell.contentView.addSubview(timeMessage)
        timeMessage.translatesAutoresizingMaskIntoConstraints = false
        if (dataMessages[indexPath.row]["read_receipts"] as? String) == "8" || ((dataMessages[indexPath.row]["credential"] as? String) == "1" && dataMessages[indexPath.row]["lock"] as? String != "2") {
            timeMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -40).isActive = true
        } else {
            timeMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -5).isActive = true
        }
        
        let statusMessage = UIImageView()
        
        if (dataMessages[indexPath.row]["attachment_flag"] as? String == "0" && dataMessages[indexPath.row]["lock"] as? String != "1") || forwardSession || deleteSession {
            var showSelectedImage = true
            if (!imageChat.isEmpty || !videoChat.isEmpty || !fileChat.isEmpty) && forwardSession {
                var file = dataMessages[indexPath.row]["image_id"] as! String
                if file.isEmpty {
                    file = dataMessages[indexPath.row]["video_id"] as! String
                    if file.isEmpty {
                        file = dataMessages[indexPath.row]["file_id"] as! String
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
            if showSelectedImage {
                let selectedImage = UIImageView()
                cell.contentView.addSubview(selectedImage)
                selectedImage.translatesAutoresizingMaskIntoConstraints = false
                selectedImage.frame.size = CGSize(width: 20, height: 20)
                var leading = selectedImage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: -20)
                selectedImage.isHidden = true
                if copySession || forwardSession || deleteSession {
                    leading = selectedImage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15)
                    selectedImage.isHidden = false
                }
                NSLayoutConstraint.activate([
                    leading,
                    selectedImage.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
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
            containerMessage.leadingAnchor.constraint(greaterThanOrEqualTo: cell.contentView.leadingAnchor, constant: 60).isActive = true
            if (dataMessages[indexPath.row]["read_receipts"] as? String) == "8" || ((dataMessages[indexPath.row]["credential"] as? String) == "1" && dataMessages[indexPath.row]["lock"] as? String != "2") {
                containerMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -40).isActive = true
            } else {
                containerMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -5).isActive = true
            }
            if isContactCenter {
                containerMessage.topAnchor.constraint(equalTo: nameSender.bottomAnchor).isActive = true
                containerMessage.trailingAnchor.constraint(equalTo: profileMessage.leadingAnchor, constant: -5).isActive = true
            } else {
                containerMessage.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5).isActive = true
                containerMessage.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -15).isActive = true
            }
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            if (dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"]as? String == "") {
                containerMessage.backgroundColor = .clear
            } else {
                containerMessage.backgroundColor = .blueBubbleColor
            }
            containerMessage.layer.cornerRadius = 10.0
            containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
            containerMessage.clipsToBounds = true
            
            timeMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            
            if (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String == "0") && (dataMessages[indexPath.row]["lock"] as? String != "2") {
                cell.contentView.addSubview(statusMessage)
                statusMessage.translatesAutoresizingMaskIntoConstraints = false
                statusMessage.bottomAnchor.constraint(equalTo: timeMessage.topAnchor).isActive = true
                statusMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
                statusMessage.widthAnchor.constraint(equalToConstant: 15).isActive = true
                statusMessage.heightAnchor.constraint(equalToConstant: 15).isActive = true
                if dataMessages[indexPath.row]["status"]! as! String == "0" {
                    statusMessage.image = UIImage(systemName: "xmark.circle")!.withTintColor(UIColor.red, renderingMode: .alwaysOriginal)
                } else if dataMessages[indexPath.row]["status"]! as! String == "1" {
                    statusMessage.image = UIImage(systemName: "clock.arrow.circlepath")!.withTintColor(UIColor.lightGray, renderingMode: .alwaysOriginal)
                } else if (dataMessages[indexPath.row]["status"]! as! String == "2" ) {
                    statusMessage.image = UIImage(named: "checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
                } else if (dataMessages[indexPath.row]["status"]! as! String == "3") {
                    statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
                } else if (dataMessages[indexPath.row]["status"]! as! String == "8") {
                    statusMessage.image = UIImage(named: "message_status_ack", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
                } else {
                    statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
                }
            }
            
        } else {
            if markerCounter != nil && dataMessages[indexPath.row]["message_id"] as? String == markerCounter {
                if isContactCenter {
                    containerMessage.topAnchor.constraint(equalTo: nameSender.bottomAnchor).isActive = true
                } else {
                    containerMessage.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 35).isActive = true
                }
                
                let newMessagesView = UIView()
                cell.contentView.addSubview(newMessagesView)
                newMessagesView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    newMessagesView.topAnchor.constraint(equalTo: newMessagesView.topAnchor),
                    newMessagesView.bottomAnchor.constraint(equalTo: containerMessage.topAnchor),
                    newMessagesView.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
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
                labelNewMessages.font = UIFont.systemFont(ofSize: 12, weight: .medium)
                labelNewMessages.text = "Unread Messages".localized()
                
            } else {
                if isContactCenter {
                    containerMessage.topAnchor.constraint(equalTo: nameSender.bottomAnchor).isActive = true
                } else {
                    containerMessage.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5).isActive = true
                }
            }
            if isContactCenter {
                containerMessage.leadingAnchor.constraint(equalTo: profileMessage.trailingAnchor, constant: 5).isActive = true
            } else {
                if copySession || forwardSession || deleteSession {
                    containerMessage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 50).isActive = true
                } else {
                    containerMessage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15).isActive = true
                }
            }
            if (dataMessages[indexPath.row]["read_receipts"] as? String) == "8" || ((dataMessages[indexPath.row]["credential"] as? String) == "1" && dataMessages[indexPath.row]["lock"] as? String != "2") {
                containerMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -40).isActive = true
            } else {
                containerMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -5).isActive = true
            }
            containerMessage.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -60).isActive = true
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            if dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"]as? String == "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String != "1") {
                containerMessage.backgroundColor = .clear
            } else {
                containerMessage.backgroundColor = .whiteBubbleColor
            }
            containerMessage.layer.cornerRadius = 10.0
            containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            containerMessage.clipsToBounds = true
            
            timeMessage.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: 8).isActive = true
        }
        
        let imageStared = UIImageView()
        if dataMessages[indexPath.row]["is_stared"] as? String == "1" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String == "0") {
            cell.contentView.addSubview(imageStared)
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
        
        if dataMessages[indexPath.row]["read_receipts"] as? String == "8" {
            let imageAckView = UIImageView()
            var imageAck = UIImage(named: "ack_icon_gray", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            if dataMessages[indexPath.row]["status"] as? String == "8" {
                imageAck = UIImage(named: "ack_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            }
            imageAckView.image = imageAck
            cell.contentView.addSubview(imageAckView)
            imageAckView.translatesAutoresizingMaskIntoConstraints = false
            imageAckView.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageAckView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                imageAckView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
                imageAckView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 30).isActive = true
            } else {
                imageAckView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
                imageAckView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -30).isActive = true
                let tap = ObjectGesture(target: self, action: #selector(tapAck(_:)))
                tap.indexPath = indexPath
                imageAckView.addGestureRecognizer(tap)
                imageAckView.isUserInteractionEnabled = true
            }
        }
        
        if (dataMessages[indexPath.row]["credential"] as? String) == "1" && (dataMessages[indexPath.row]["lock"] as? String) != "2" {
            let imageCredentialView = UIImageView()
            let imageCredential = UIImage(named: "confidential_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            imageCredentialView.image = imageCredential
            cell.contentView.addSubview(imageCredentialView)
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
        
        if dataMessages[indexPath.row][TypeDataMessage.last_edit] != nil && dataMessages[indexPath.row][TypeDataMessage.last_edit] as! Int64 != 0 {
            let editedText = UILabel()
            editedText.text = "Edited".localized()
            editedText.font = UIFont.systemFont(ofSize: 10, weight: .medium)
            editedText.textColor = .lightGray
            cell.contentView.addSubview(editedText)
            editedText.translatesAutoresizingMaskIntoConstraints = false
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                editedText.trailingAnchor.constraint(equalTo: timeMessage.leadingAnchor, constant: -2).isActive = true
            } else {
                editedText.leadingAnchor.constraint(equalTo: timeMessage.trailingAnchor, constant: 2).isActive = true
            }
            editedText.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor).isActive = true
        }
        
        let messageText = UILabel()
        messageText.numberOfLines = 0
        messageText.lineBreakMode = .byWordWrapping
        containerMessage.addSubview(messageText)
        messageText.translatesAutoresizingMaskIntoConstraints = false
        let topMarginText = messageText.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15)
        topMarginText.isActive = true
        messageText.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        messageText.font = .systemFont(ofSize: 12)
        if dataMessages[indexPath.row]["attachment_flag"] as? String == "27" || dataMessages[indexPath.row]["attachment_flag"] as? String == "26" || dataMessages[indexPath.row]["message_scope_id"] as? String == "18" {
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
            if dataMessages[indexPath.row]["attachment_flag"] as! String == "26" {
                imageLS.image = UIImage(named: "pb_seminar_wpr", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
            } else if dataMessages[indexPath.row]["attachment_flag"] as! String == "27" {
                imageLS.image = UIImage(named: "pb_live_tv", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
            } else if dataMessages[indexPath.row]["message_scope_id"] as? String == "18" {
                imageLS.image = UIImage(systemName: "doc.richtext.fill")
                imageLS.tintColor = .mainColor
            }
        } else {
            messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
        }
        if dataMessages[indexPath.row]["f_pin"] as? String == "-999" && (dataMessages[indexPath.row]["blog_id"] as? String) != nil && !(dataMessages[indexPath.row]["blog_id"] as! String).isEmpty && (dataMessages[indexPath.row]["message_text"] as! String).contains("Berikut QR Code dan detil booking Anda") {
            messageText.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: -115).isActive = true
            let imageQR = UIImageView()
            containerMessage.addSubview(imageQR)
            imageQR.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageQR.centerXAnchor.constraint(equalTo: containerMessage.centerXAnchor),
                imageQR.topAnchor.constraint(equalTo: messageText.bottomAnchor),
                imageQR.widthAnchor.constraint(equalToConstant: 100.0),
                imageQR.heightAnchor.constraint(equalToConstant: 100.0)
            ])
            imageQR.image = generateQRCode(from: dataMessages[indexPath.row]["blog_id"] as! String)
        } else {
            messageText.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: -15).isActive = true
        }
        messageText.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
        var textChat = (dataMessages[indexPath.row]["message_text"] as? String) ?? ""
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
        
        let imageSticker = UIImageView()
        var stringLS = ""
        if let attachmentFlag = dataMessages[indexPath.row]["attachment_flag"], let attachmentFlag = attachmentFlag as? String {
            if attachmentFlag == "27" || attachmentFlag == "26" { // live streaming
                let data = textChat
                if let json = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                    let title = json["title"] as? String ?? ""
                    let description = json["description"] as? String ?? ""
                    let start = json["time"] as? Int64 ?? 0
                    let by = json["by"] as? String ?? ""
                    let textLS = "Live Streaming".localized()
                    var type = "*\(textLS)*"
                    if attachmentFlag == "26" {
                        let textSeminar = "Seminar".localized()
                        type = "*\(textSeminar)*"
                    }
                    if let c = User.getData(pin: by) {
                        let name = c.fullName
                        stringLS = "\(type) \nTitle: \(title) \nDescription: \(description) \nStart: \(Date(milliseconds: start).format(dateFormat: "dd/MM/yyyy HH:mm")) \nBroadcaster: \(name)"
                    } else {
                        stringLS = ("\(type) \nTitle: \(title) \nDescription: \(description) \nStart: \(Date(milliseconds: start).format(dateFormat: "dd/MM/yyyy HH:mm"))")
                    }
                    messageText.attributedText = stringLS.richText()
                }
            }
            else if attachmentFlag == "11" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String != "1") && (dataMessages[indexPath.row]["lock"] as? String != "2") {
                messageText.text = ""
                topMarginText.constant = topMarginText.constant + 100
                containerMessage.addSubview(imageSticker)
                imageSticker.translatesAutoresizingMaskIntoConstraints = false
                let data = queryMessageReply(message_id: reffChat)
                if reffChat.isEmpty || data.count == 0 {
                    imageSticker.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
                    imageSticker.widthAnchor.constraint(equalToConstant: 80).isActive = true
                } else {
                    imageSticker.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
                }
                imageSticker.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                imageSticker.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                imageSticker.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                imageSticker.image = UIImage(named: (textChat.components(separatedBy: "/")[1]), in: Bundle.resourceBundle(for: Nexilis.self), with: nil) //resourcesMediaBundle
                imageSticker.contentMode = .scaleAspectFit
            } else if dataMessages[indexPath.row]["message_scope_id"] as! String == "18" {
                let data = textChat
                if let jsonForm = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                    let form_title = jsonForm["form_title"] as! String
                    let club_type = jsonForm["club_type"] as! String
                    let province = jsonForm["province"] as! String
                    let club = jsonForm["club"] as! String
                    messageText.attributedText = "*\(form_title.replacingOccurrences(of: "+", with: " "))* \nClub Type: \(club_type) \nProvince: \(province) \nClub Name: \(club) ".richText()
                }
            }
            else {
                messageText.attributedText = textChat.richText()
                modifyText()
            }
        } else {
            messageText.attributedText = textChat.richText()
            modifyText()
        }
        
        func modifyText() {
            
            func ranges(of word: String, in string: String) -> [NSRange] {
                var result: [NSRange] = []
                var startIndex = string.startIndex
                
                while let range = string[startIndex...].range(of: word) {
                    let nsRange = NSRange(range, in: string)
                    result.append(nsRange)
                    startIndex = range.upperBound
                }
                
                return result
            }
            
            messageText.isUserInteractionEnabled = false
            if !textChat.isEmpty {
                if textChat.contains("■"){
                    textChat = textChat.components(separatedBy: "■")[0]
                    textChat = textChat.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                let listTextEnter = textChat.split(separator: "\n")
                let finalAtribute = textChat.richText()
                var containsLink = false
                var listRange: [NSRange] = []
                for j in 0...listTextEnter.count - 1 {
                    let listText = listTextEnter[j].split(separator: " ")
                    if listText.count > 0 {
                        for i in 0...listText.count - 1 {
                            if listText[i].lowercased().checkStartWithLink() {
                                var rangeTapLink = (finalAtribute.string as NSString).range(of: String(listText[i]))
                                func checkContainsRange() {
                                    if listRange.contains(rangeTapLink) {
                                        let allRanges = ranges(of: String(listText[i]), in: finalAtribute.string)
                                        for allRange in allRanges {
                                            if !listRange.contains(allRange) {
                                                rangeTapLink = allRange
                                                break
                                            }
                                        }
                                    }
                                    listRange.append(rangeTapLink)
                                }
                                checkContainsRange()
                                finalAtribute.addAttributes([.foregroundColor: UIColor.blue, .underlineStyle: NSUnderlineStyle.single.rawValue], range: rangeTapLink)
                                if !containsLink {
                                    containsLink = true
                                }
                            }
                        }
                    }
                }
                messageText.attributedText = finalAtribute
                if containsLink && !copySession && !forwardSession && !deleteSession && !self.removed {
                    messageText.isUserInteractionEnabled = true
                    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressLink(_:)))
                    longPress.minimumPressDuration = 0.1
                    containerMessage.addGestureRecognizer(longPress)
                }
            }
        }
        
        if !copySession && !forwardSession && !deleteSession && !self.removed && messageText.isUserInteractionEnabled == false {
            let interaction = UIContextMenuInteraction(delegate: self)
            containerMessage.addInteraction(interaction)
            containerMessage.isUserInteractionEnabled = true
        }
        
        if isSearching && textSearch.count > 1 {
            messageText.attributedText = stringLS.isEmpty ? textChat.richText(isSearching: true, textSearch: textSearch) : stringLS.richText(isSearching: true, textSearch: textSearch)
            if textChat.lowercased().contains(textSearch) {
                countMatchesSearch += 1
            }
        }
        
        let stringDate = (dataMessages[indexPath.row]["server_date"] as? String) ?? ""
        if !stringDate.isEmpty {
            if (dataMessages[indexPath.row]["credential"] as? String) == "1" && dataMessages[indexPath.row]["lock"] as? String != "2" {
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
            timeMessage.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        }
        
        let imageThumb = UIImageView()
        let containerViewFile = UIView()
        
        if (!thumbChat.isEmpty && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String != "1") && (dataMessages[indexPath.row]["lock"] as? String != "2")) {
            if let listImages = groupImages[messageIdChat] {
                timeMessage.isHidden = true
                statusMessage.isHidden = true
                imageStared.isHidden = true
                topMarginText.constant = topMarginText.constant + 225
                let listImageThumb: [UIImageView] = [UIImageView(), UIImageView(), UIImageView(), UIImageView()]
                for i in 0..<4 {
                    containerMessage.addSubview(listImageThumb[i])
                    listImageThumb[i].layer.cornerRadius = 5.0
                    listImageThumb[i].clipsToBounds = true
                    listImageThumb[i].contentMode = .scaleAspectFill
                    let widthHeightImage: CGFloat = 120
                    switch i {
                        case 0:
                            listImageThumb[i].anchor(top: containerMessage.topAnchor, left: containerMessage.leftAnchor, paddingTop: 5, paddingLeft: 5, width: widthHeightImage, height: widthHeightImage)
                        case 1:
                            listImageThumb[i].anchor(top: containerMessage.topAnchor, left: listImageThumb[0].rightAnchor, right: containerMessage.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingRight: 5, width: widthHeightImage, height: widthHeightImage)
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
//                        let image = UIGraphicsRenderer.renderImageAt(url: thumbURL as NSURL, size: CGSize(width: 250, height: 250))
                        listImageThumb[i].image = image

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
                    timeInImage.font = UIFont.systemFont(ofSize: 10, weight: .medium)
                    
                    if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                        let statusInImage = UIImageView()
                        containerTimeStatus.addSubview(statusInImage)
                        statusInImage.anchor(right: containerTimeStatus.rightAnchor, centerY: containerTimeStatus.centerYAnchor, width: 15, height: 15)
                        if listImages[i].status == "0" {
                            statusMessage.image = UIImage(systemName: "xmark.circle")!.withTintColor(UIColor.red, renderingMode: .alwaysOriginal)
                        } else if listImages[i].status == "1" {
                            statusInImage.image = UIImage(systemName: "clock.arrow.circlepath")!.withTintColor(UIColor.white, renderingMode: .alwaysOriginal)
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
                if reffChat.isEmpty || data.count == 0 {
                    imageThumb.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
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
//                    let image = UIGraphicsRenderer.renderImageAt(url: thumbURL as NSURL, size: CGSize(width: 250, height: 250))
                    let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(videoChat)
                    let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(imageChat)
                    if !FileManager.default.fileExists(atPath: imageURL.path) && !FileManager.default.fileExists(atPath: videoURL.path) && !FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) && !FileEncryption.shared.isSecureExists(filename: videoURL.lastPathComponent) {
                        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
                        let blurEffectView = UIVisualEffectView(effect: blurEffect)
                        blurEffectView.frame = CGRect(x: 0, y: 0, width: imageThumb.frame.size.width, height: imageThumb.frame.size.height)
                        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                        imageThumb.addSubview(blurEffectView)
                        if !imageChat.isEmpty {
                            let imageDownload = UIImageView(image: UIImage(systemName: "arrow.down.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .default)))
                            imageThumb.addSubview(imageDownload)
                            imageDownload.tintColor = .black.withAlphaComponent(0.3)
                            imageDownload.translatesAutoresizingMaskIntoConstraints = false
                            imageDownload.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                            imageDownload.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                        }
                    }
                    
                }
                
                if (videoChat != "") {
                    let imagePlay = UIImageView(image: UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .default))?.imageWithInsets(insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))?.withTintColor(.white))
                    imagePlay.circle()
                    imageThumb.addSubview(imagePlay)
                    imagePlay.backgroundColor = .black.withAlphaComponent(0.3)
                    imagePlay.translatesAutoresizingMaskIntoConstraints = false
                    imagePlay.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                    imagePlay.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
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
                    imageThumb.isUserInteractionEnabled = true
                    imageThumb.addGestureRecognizer(objectTap)
                    objectTap.image_id = imageChat
                    objectTap.video_id = videoChat
                    objectTap.imageView = imageThumb
                    objectTap.indexPath = indexPath
                }
            }
        }
        
        if (fileChat != "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String != "1") && dataMessages[indexPath.row]["message_scope_id"] as! String != "18" && (dataMessages[indexPath.row]["lock"] as? String != "2")) {
            topMarginText.constant = topMarginText.constant + 55
            
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            let arrExtFile = (textChat.components(separatedBy: "|")[0]).split(separator: ".")
            let finalExtFile = arrExtFile[arrExtFile.count - 1]
            if let dirPath = paths.first {
                let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(fileChat)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    if let dataFile = try? Data(contentsOf: fileURL) {
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
                    } else {
                        messageText.text = ""
                    }
                }
                else if FileEncryption.shared.isSecureExists(filename: fileChat) {
                    if let dataFile = try? FileEncryption.shared.readSecure(filename: fileChat) {
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
                    } else {
                        messageText.text = ""
                    }
                }
            }
            
            containerMessage.addSubview(containerViewFile)
            containerViewFile.translatesAutoresizingMaskIntoConstraints = false
            let data = queryMessageReply(message_id: reffChat)
            if reffChat.isEmpty || data.count == 0 {
                containerViewFile.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
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
            nameFile.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            nameFile.textColor = .white
            nameFile.text = textChat.components(separatedBy: "|")[0]
            
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
                containerViewFile.addGestureRecognizer(objectTap)
                objectTap.containerFile = containerViewFile
                objectTap.labelFile = nameFile
                objectTap.file_id = fileChat
                objectTap.indexPath = indexPath
            }
        }
        
        let containerLinkMessage = UIView()
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
                func showLink() {
                    if let data = try! JSONSerialization.jsonObject(with: dataURL.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                        let title = data["title"] as! String
                        let description = data["description"] as! String
                        let imageUrl = data["imageUrl"] as? String
                        let link = data["link"] as! String
                        
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
                            imagePreview.contentMode = .scaleToFill
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
                        titlePreview.font = UIFont.systemFont(ofSize: 14.0, weight: .bold)
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
                        descPreview.font = UIFont.systemFont(ofSize: 12.0)
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
                        linkPreview.font = UIFont.systemFont(ofSize: 10.0)
                        linkPreview.textColor = .gray
                        linkPreview.numberOfLines = 1
                        
                        if !copySession && !forwardSession && !deleteSession {
                            let objectTap = ObjectGesture(target: self, action: #selector(tapMessageText(_:)))
                            objectTap.message_id = text
                            containerLinkMessage.addGestureRecognizer(objectTap)
                        }
                    }
                }
                var dataURL = ""
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
                        let title = result.title ?? "No Title"
                        let description = text.contains("google.com") ? "" : result.description
                        let imageUrl = result.icon
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
        
        if (reffChat != "" && dataMessages[indexPath.row]["message_scope_id"] as! String != "18") {
            let data = queryMessageReply(message_id: reffChat)
            if data.count != 0 {
                topMarginText.constant = topMarginText.constant + 55
                
                let containerReply = UIView()
                containerMessage.addSubview(containerReply)
                containerReply.translatesAutoresizingMaskIntoConstraints = false
                containerReply.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                containerReply.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
                if thumbChat != "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String != "1") {
                    containerReply.bottomAnchor.constraint(equalTo: imageThumb.topAnchor, constant: -5).isActive = true
                } else if fileChat != "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String != "1") {
                    containerReply.bottomAnchor.constraint(equalTo: containerViewFile.topAnchor, constant: -5).isActive = true
                } else if containerMessage.subviews.contains(containerLinkMessage) {
                    containerReply.bottomAnchor.constraint(equalTo: containerLinkMessage.topAnchor, constant: -5).isActive = true
                } else if dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String != "1") {
                    containerReply.bottomAnchor.constraint(equalTo: imageSticker.topAnchor, constant: -5).isActive = true
                } else {
                    containerReply.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                }
                containerReply.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                containerReply.heightAnchor.constraint(equalToConstant: 50).isActive = true
                containerReply.backgroundColor = .black.withAlphaComponent(0.2)
                containerReply.layer.cornerRadius = 5
                containerReply.clipsToBounds = true
                
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
                titleReply.font = UIFont.systemFont(ofSize: 12).bold
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
                    if isContactCenter {
                        let user: [User] = users.filter({$0.pin == data["f_pin"] as? String})
                        titleReply.text = user.first!.fullName
                    } else {
                        titleReply.text = self.dataPerson["name"]!!
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
                containerReply.addSubview(contentReply)
                contentReply.translatesAutoresizingMaskIntoConstraints = false
                contentReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
                contentReply.bottomAnchor.constraint(equalTo: containerReply.bottomAnchor, constant: -10).isActive = true
                contentReply.font = UIFont.systemFont(ofSize: 10)
                let message_text = data["message_text"] as! String
                let attachment_flag = data["attachment_flag"] as! String
                let thumb_chat = data["thumb_id"] as! String
                let image_chat = data["image_id"] as! String
                let video_chat = data["video_id"] as! String
                let file_chat = data["file_id"] as! String
                if (attachment_flag == "0" && thumb_chat == "") {
                    contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    contentReply.attributedText = message_text.richText()
                } else if (attachment_flag == "1" || image_chat != "") {
                    if (message_text == "") {
                        contentReply.text = "📷 Photo".localized()
                    } else {
                        contentReply.attributedText = message_text.richText()
                    }
                } else if (attachment_flag == "2" || video_chat != "") {
                    if (message_text == "") {
                        contentReply.text = "📹 Video".localized()
                    } else {
                        contentReply.attributedText = message_text.richText()
                    }
                } else if (attachment_flag == "6" || file_chat != ""){
                    contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    contentReply.text = "📄 \(message_text.components(separatedBy: "|")[0])"
                } else if (attachment_flag == "11") {
                    contentReply.text = "❤️ Sticker"
                }
                contentReply.textColor = .white.withAlphaComponent(0.8)
                
                if (attachment_flag == "1" || attachment_flag == "2" || image_chat != "" || video_chat != "") {
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if let dirPath = paths.first {
                        let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(thumb_chat)
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
                }
                if (attachment_flag == "11" && message_text.components(separatedBy: "/").count > 1) {
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
                    objectTap.message_id = data["message_id"] as! String
                }
            }
        }
//        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureCellAction))
//        panGestureRecognizer.delegate = self
//        cellMessage.addGestureRecognizer(panGestureRecognizer)
        return cell
    }
    
    @objc func imageGroupingTapped(_ sender: ObjectGesture) {
        let listGroupingImages = ListGroupImages()
        listGroupingImages.imageTapped = sender.indexImageTapped
        listGroupingImages.listGroupingImages = sender.listImageFromGrouping
        listGroupingImages.titleName = titleText
        listGroupingImages.isInitiator = sender.isInitiator
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
                                    if let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == sender.listImageFromGrouping[0].messageId }) {
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
                                    if let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == sender.listImageFromGrouping[0].messageId }) {
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
                                if let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == sender.listImageFromGrouping[0].messageId }) {
                                    self.dataMessages.remove(at: idx)
                                    self.dataMessages.insert(updatedData[0].dataMessage, at: idx)
                                    groupImages.removeValue(forKey: sender.listImageFromGrouping[0].messageId)
                                    groupImages[updatedData[0].messageId] = updatedData
                                }
                            }
                        } else {
                            if let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == sender.listImageFromGrouping[0].messageId }) {
                                groupImages.removeValue(forKey: sender.listImageFromGrouping[0].messageId)
                                self.dataMessages.remove(at: idx)
                                let dataMessageInGrouping = updatedData.map({ $0.dataMessage })
                                self.dataMessages.insert(contentsOf: dataMessageInGrouping, at: idx)
                            }
                        }
                    }
                } else {
                    groupImages.removeValue(forKey: sender.listImageFromGrouping[0].messageId)
                    if let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == sender.listImageFromGrouping[0].messageId }) {
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
        if blocking == "1" {
            self.view.makeToast("You blocked this user".localized())
            return
        }
        if blocking == "-1" {
            self.view.makeToast("You have been blocked by this user".localized())
            return
        }
        let indexPath = sender.indexPath
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath.section]})
        if dataMessages[indexPath.row]["status"] as! String == "8" {
            return
        }
        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        DispatchQueue.global().async {
            let result = Nexilis.write(message: CoreMessage_TMessageBank.getAckLocationMessage(f_pin: dataMessages[indexPath.row]["f_pin"] as! String, message_id: dataMessages[indexPath.row]["message_id"] as! String, l_pin: dataMessages[indexPath.row]["l_pin"] as! String, server_date: "\(Date().currentTimeMillis())", message_scope_id: dataMessages[indexPath.row]["message_scope_id"] as! String, longitude: "", latitude: "", description: ""))
            if result != nil {
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                            "status" : "8"
                        ], _where: "message_id = '\(dataMessages[indexPath.row]["message_id"] as! String)'")
                    } catch {
                        rollback.pointee = true
                        print("Access database error: \(error.localizedDescription)")
                    }
                })
                DispatchQueue.main.async {
                    if let index = self.dataMessages.firstIndex(where: {$0["message_id"] as? String == dataMessages[indexPath.row]["message_id"] as? String}) {
                        self.dataMessages[index]["status"] = "8"
                        let section = self.dataDates.firstIndex(of: self.dataMessages[index]["chat_date"] as! String)
                        let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[section!]}).firstIndex(where: { $0["message_id"] as! String == self.dataMessages[index]["message_id"] as! String})
                        if row != nil && section != nil {
                            self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                        }
                        self.showToast(message: "Confirmation Success.".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                    }
                }
            }
        }
    }
    
//    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        let velocity : CGPoint = gestureRecognizer.location(in: tableChatView)
//        if velocity.x < 0 {
//            return false
//        }
//        return abs(Float(velocity.x)) > abs(Float(velocity.y))
//    }
//
//    @objc func panGestureCellAction(recognizer: UIPanGestureRecognizer)  {
//        let translation = recognizer.translation(in: tableChatView)
//        let x = recognizer.view?.frame.origin.x ?? 0
//        if x >= -(recognizer.view?.frame.size.width ?? 0) * 0.05 {
//            recognizer.view?.center = CGPoint(
//                x: (recognizer.view?.center.x ?? 0) + translation.x,
//                y: (recognizer.view?.center.y ?? 0))
//            recognizer.setTranslation(CGPoint(x: 0, y: 0), in: view)
//            if (recognizer.view?.frame.origin.x ?? 0) > UIScreen.main.bounds.size.width * 0.9 {
//                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
//                    recognizer.view?.frame = CGRect(x: 0, y: recognizer.view?.frame.origin.y ?? 0, width: recognizer.view?.frame.size.width ?? 0, height: recognizer.view?.frame.size.height ?? 0)
//                })
//            }
//        }
//        if x <= -(recognizer.view?.frame.size.width ?? 0) * 0.05 {
//            let idMe = User.getMyPin() as String?
//            let indexPath = self.tableChatView.indexPath(for: recognizer.view! as! UITableViewCell)
//            let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath!.section]})
//            if (dataMessages[indexPath!.row]["f_pin"] as? String == idMe) {
//                let messageInfoVC = MessageInfo()
//                messageInfoVC.data = dataMessages[indexPath!.row]
//                self.navigationController?.pushViewController(messageInfoVC, animated: true)
//                return
//            }
//        }
//        if x >= ((recognizer.view?.frame.size.width ?? 0) * 0.2) {
//            if !hapticSwipeLeft {
//                UINotificationFeedbackGenerator().notificationOccurred(.success)
//            }
//            hapticSwipeLeft = true
//        } else if x < ((recognizer.view?.frame.size.width ?? 0) * 0.2) {
//            hapticSwipeLeft = false
//        }
//        if recognizer.state == .ended {
//            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
//                recognizer.view?.frame = CGRect(x: 0, y: recognizer.view?.frame.origin.y ?? 0, width: recognizer.view?.frame.size.width ?? 0, height: recognizer.view?.frame.size.height ?? 0)
//            } completion: { (finished) in
//                if x > ((recognizer.view?.frame.size.width ?? 0) * 0.2) {
//                    self.hapticSwipeLeft = false
//
//                }
//            }
//        }
//    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        dataDates.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = dataMessages.filter({ $0["chat_date"] as! String == dataDates[section] }).count
        return count
    }
    
    @objc func contentMessageTapped(_ sender: ObjectGesture) {
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if (sender.image_id != "") {
            if let dirPath = paths.first {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.image_id)
                if FileManager.default.fileExists(atPath: imageURL.path) {
                    let image    = UIImage(contentsOfFile: imageURL.path)
                    let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
                    previewImageVC.image = image
                    previewImageVC.isHiddenTextField = true
                    previewImageVC.modalPresentationStyle = .custom
                    previewImageVC.modalTransitionStyle  = .crossDissolve
                    self.present(previewImageVC, animated: true, completion: nil)
                } else if FileEncryption.shared.isSecureExists(filename: sender.image_id) {
                    do {
                        let data = try FileEncryption.shared.readSecure(filename: sender.image_id)
                        let image = UIImage(data: data!)
                        let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
                        previewImageVC.image = image
                        previewImageVC.isHiddenTextField = true
                        previewImageVC.modalPresentationStyle = .custom
                        previewImageVC.modalTransitionStyle  = .crossDissolve
                        self.present(previewImageVC, animated: true, completion: nil)
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
                        do {
                            let secureName = try FileEncryption.shared.writeSecure(filename: name)?[0] as! String
                            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                            if let dirPath = paths.first {
                                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.image_id)
                                if FileManager.default.fileExists(atPath: imageURL.path) {
                                    let image    = UIImage(contentsOfFile: imageURL.path)
                                    let save: Bool = SecureUserDefaults.shared.value(forKey: "saveToGallery") ?? false
                                    if save {
                                        UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
                                    }
                                }
                                else if FileEncryption.shared.isSecureExists(filename: secureName) {
                                    if let secureData = try FileEncryption.shared.readSecure(filename: secureName) {
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
                        DispatchQueue.main.async {
                            activityIndicator.stopAnimating()
                            self.tableChatView.reloadRows(at: [sender.indexPath], with: .none)
                        }
                    }
                }
            }
        } else if (sender.video_id != "") {
            if let dirPath = paths.first {
                let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.video_id)
                if FileManager.default.fileExists(atPath: videoURL.path) {
                    let player = AVPlayer(url: videoURL as URL)
                    let playerVC = AVPlayerViewController()
                    playerVC.modalPresentationStyle = .custom
                    playerVC.player = player
                    self.present(playerVC, animated: true, completion: nil)
                } else if FileEncryption.shared.isSecureExists(filename: sender.video_id) {
                    do {
                        if let secureData = try FileEncryption.shared.readSecure(filename: sender.video_id) {
                            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                            let tempPath = cachesDirectory.appendingPathComponent(sender.video_id)
                            try secureData.write(to: tempPath)
                            let player = AVPlayer(url: tempPath as URL)
                            let playerVC = AVPlayerViewController()
                            playerVC.modalPresentationStyle = .custom
                            playerVC.player = player
                            self.present(playerVC, animated: true, completion: nil)
                        }
                    } catch {
                        
                    }
                } else {
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
                    trackShape.strokeColor = UIColor.blueBubbleColor.withAlphaComponent(0.3).cgColor
                    container.backgroundColor = .clear
                    container.layer.addSublayer(trackShape)
                    let shapeLoading = CAShapeLayer()
                    shapeLoading.path = circlePath.cgPath
                    shapeLoading.fillColor = UIColor.clear.cgColor
                    shapeLoading.lineWidth = 10
                    shapeLoading.strokeEnd = 0
                    shapeLoading.strokeColor = UIColor.blueBubbleColor.cgColor
                    container.layer.addSublayer(shapeLoading)
                    let imageDownload = UIImageView(image: UIImage(systemName: "arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                    imageDownload.tintColor = .white
                    container.addSubview(imageDownload)
                    imageDownload.translatesAutoresizingMaskIntoConstraints = false
                    imageDownload.centerXAnchor.constraint(equalTo: sender.imageView.centerXAnchor).isActive = true
                    imageDownload.centerYAnchor.constraint(equalTo: sender.imageView.centerYAnchor).isActive = true
                    imageDownload.widthAnchor.constraint(equalToConstant: 30).isActive = true
                    imageDownload.heightAnchor.constraint(equalToConstant: 30).isActive = true
                    Download().startHTTP(forKey: sender.video_id, isImage: false) { (name, progress) in
                        DispatchQueue.main.async {
                            guard progress == 100 else {
                                shapeLoading.strokeEnd = CGFloat(progress / 100)
                                return
                            }
                            do {
                                if let secureName = try FileEncryption.shared.writeSecure(filename: name)?[0] as? String {
                                    let secureData = try FileEncryption.shared.readSecure(filename: secureName)
                                    let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                                    let tempPath = cachesDirectory.appendingPathComponent(name)
                                    try secureData!.write(to: tempPath)
                                    let save: Bool = SecureUserDefaults.shared.value(forKey: "saveToGallery") ?? false
                                    if save {
                                        PHPhotoLibrary.shared().performChanges({
                                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempPath)
                                        }) { saved, error in
                                            
                                        }
                                    }
                                } else {
                                    let save: Bool = SecureUserDefaults.shared.value(forKey: "saveToGallery") ?? false
                                    if save {
                                        let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.video_id)
                                        PHPhotoLibrary.shared().performChanges({
                                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                                        }) { saved, error in
                                            
                                        }
                                    }
                                }
                            } catch {
                                
                            }
                            let idx = self.dataMessages.firstIndex(where: { $0["video_id"] as! String == sender.video_id})
                            if idx != nil {
                                self.dataMessages[idx!]["progress"] = progress
                                self.tableChatView.reloadRows(at: [sender.indexPath], with: .none)
                            }
                        }
                    }
                }
            }
        } else if (sender.file_id != "") {
            if let dirPath = paths.first {
                let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.file_id)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    self.previewItem = fileURL as NSURL
                    let previewController = QLPreviewController()
                    let rightBarButton = UIBarButtonItem()
                    previewController.navigationItem.rightBarButtonItem = rightBarButton
                    previewController.dataSource = self
                    previewController.modalPresentationStyle = .custom
                    
                    self.present(previewController, animated: true)
                } else if FileEncryption.shared.isSecureExists(filename: sender.file_id) {
                    do {
                        if let docData = try FileEncryption.shared.readSecure(filename: sender.file_id) {
                            
                            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                            let tempPath = cachesDirectory.appendingPathComponent(sender.file_id)
                            try docData.write(to: tempPath)
                            self.previewItem = tempPath as NSURL
                            let previewController = QLPreviewController()
                            let rightBarButton = UIBarButtonItem()
                            previewController.navigationItem.rightBarButtonItem = rightBarButton
                            previewController.dataSource = self
                            previewController.modalPresentationStyle = .custom
                            self.present(previewController,animated: true)
                        }
                    }
                    catch {
                        
                    }
                }   else {
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
                    trackShape.strokeColor = UIColor.blueBubbleColor.withAlphaComponent(0.3).cgColor
                    containerLoading.layer.addSublayer(trackShape)
                    let shapeLoading = CAShapeLayer()
                    shapeLoading.path = circlePath.cgPath
                    shapeLoading.fillColor = UIColor.clear.cgColor
                    shapeLoading.lineWidth = 3
                    shapeLoading.strokeEnd = 0
                    shapeLoading.strokeColor = UIColor.blueBubbleColor.cgColor
                    containerLoading.layer.addSublayer(shapeLoading)
                    let imageupload = UIImageView(image: UIImage(systemName: "arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                    imageupload.tintColor = .white
                    containerLoading.addSubview(imageupload)
                    imageupload.translatesAutoresizingMaskIntoConstraints = false
                    imageupload.centerYAnchor.constraint(equalTo: containerLoading.centerYAnchor).isActive = true
                    imageupload.centerXAnchor.constraint(equalTo: containerLoading.centerXAnchor).isActive = true
                    
                    Download().startHTTP(forKey: sender.file_id, isImage: false) { (name, progress) in
                        DispatchQueue.main.async {
                            guard progress == 100 else {
                                shapeLoading.strokeEnd = CGFloat(progress / 100)
                                return
                            }
                            do {
                                try FileEncryption.shared.writeSecure(filename: name)
                            } catch {
                                
                            }
                            let idx = self.dataMessages.firstIndex(where: { $0["file_id"] as! String == sender.file_id})
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
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == sender.message_id})
                if idx == nil {
                    return
                }
                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                if section == nil {
                    return
                }
                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[section!]}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String})
                if row == nil {
                    return
                }
                let indexPath = IndexPath(row: row!, section: section!)
                self.tableChatView.scrollToRow(at: indexPath, at: .middle, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let cell = self.tableChatView.cellForRow(at: indexPath) {
                        let containerMessage = cell.contentView.subviews[0]
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
    
    @objc func handleLongPressLink(_ gestureRecognizer: UILongPressGestureRecognizer) {
        func showMenuContext() {
            if gestureRecognizer.state == .cancelled || gestureRecognizer.state == .ended{
                timerCheckLink?.invalidate()
            } else if gestureRecognizer.state == .began {
                timerCheckLink = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: {_ in
                    let interaction = UIContextMenuInteraction(delegate: self)
                    gestureRecognizer.view!.addInteraction(interaction)
                    guard let interaction = gestureRecognizer.view!.interactions.first,
                          let data = Data(base64Encoded: "X3ByZXNlbnRNZW51QXRMb2NhdGlvbjo="),
                          let str = String(data: data, encoding: .utf8)
                    else {
                        return
                    }
                    let selector = NSSelectorFromString(str)
                    guard interaction.responds(to: selector) else {
                        return
                    }
                    let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                    impactHeavy.impactOccurred()
                    interaction.perform(selector, with: self.view)
                    self.showMenuContext = true
                })
            }
        }
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: self.view)
            touchedSubview = self.view.hitTest(touchPoint, with: nil) ?? UIView()
            if !(touchedSubview is UILabel) {
                showMenuContext()
            }
        }
        guard let label = touchedSubview as? UILabel else { return }
        let touchPointLabel = gestureRecognizer.location(in: label)

        if let text = label.text, let range = getWordRange(at: touchPointLabel, in: label) {
            let word = String(text[range])
            if word.starts(with: "www.") || word.starts(with: "https://") || word.starts(with: "http://") {
                if gestureRecognizer.state == .cancelled || gestureRecognizer.state == .ended {
                    timerCheckLink?.invalidate()
                    if label.isHighlighted {
                        var stringURl = word
                        if stringURl.starts(with: "www.") {
                            stringURl = "https://" + stringURl.replacingOccurrences(of: "www.", with: "")
                        }
                        guard let url = URL(string: stringURl) else { return }
                        UIApplication.shared.open(url)
                        label.attributedText = removeHighlightedText(for: text, in: range, label: label)
                    }
                } else if gestureRecognizer.state == .began {
                    label.attributedText = highlightedText(for: text, in: range, label: label)
                    timerCheckLink = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {_ in
                        UIPasteboard.general.string = word
                        self.showToast(message: "Link Copied".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                        label.attributedText = self.removeHighlightedText(for: text, in: range, label: label)
                    })
                }
            } else {
                showMenuContext()
            }
        } else {
            showMenuContext()
        }
    }
    
    func getWordRange(at point: CGPoint, in label: UILabel) -> Range<String.Index>? {
        guard let text = label.text else { return nil }
        
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText ?? NSAttributedString())
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.size = label.bounds.size
        
        let characterIndex = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        if characterIndex == text.count - 1 {
            return nil
        }
        var wordStartIndex = characterIndex
        while wordStartIndex > 0 && text[text.index(text.startIndex, offsetBy: wordStartIndex - 1)] != " " && text[text.index(text.startIndex, offsetBy: wordStartIndex - 1)] != "\n" {
            wordStartIndex -= 1
        }
        
        var wordEndIndex = characterIndex
        while wordEndIndex < text.count && text[text.index(text.startIndex, offsetBy: wordEndIndex)] != " " && text[text.index(text.startIndex, offsetBy: wordEndIndex)] != "\n" {
            wordEndIndex += 1
        }
        
        return text.index(text.startIndex, offsetBy: wordStartIndex)..<text.index(text.startIndex, offsetBy: wordEndIndex)
    }

    func highlightedText(for text: String, in range: Range<String.Index>, label: UILabel) -> NSAttributedString {
        let mutableAttributedString = label.attributedText!.mutableCopy() as! NSMutableAttributedString
        mutableAttributedString.addAttribute(.backgroundColor, value: UIColor.lightGray.withAlphaComponent(0.5), range: NSRange(range, in: text))
        label.isHighlighted = true
        return mutableAttributedString
    }
    
    func removeHighlightedText(for text: String, in range: Range<String.Index>, label: UILabel) -> NSAttributedString {
        let mutableAttributedString = label.attributedText!.mutableCopy() as! NSMutableAttributedString
        mutableAttributedString.removeAttribute(.backgroundColor, range: NSRange(range, in: text))
        label.isHighlighted = false
        return mutableAttributedString
    }
    
    @objc func tapMessageText(_ sender: ObjectGesture) {
        var stringURl = sender.message_id
        if stringURl.lowercased().starts(with: "www.") {
            stringURl = "https://" + stringURl.replacingOccurrences(of: "www.", with: "")
        }
        guard let url = URL(string: stringURl) else { return }
        UIApplication.shared.open(url)
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
//        messageInfoVC.data = dataMessages[indexPath.row]
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
    
    private func handleReply(indexPath: IndexPath, dataMessagesImage: [String: Any?] = [:], reffId: String = "") {
        var dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath.section]})
        if reffId.isEmpty {
            self.deleteReplyView()
            if dataMessagesImage.count != 0 {
                dataMessages = [dataMessagesImage]
            } else {
                self.textFieldSend.becomeFirstResponder()
            }
            self.reffId = dataMessages[indexPath.row]["message_id"] as? String
        } else {
            dataMessages = self.dataMessages.filter({ $0["message_id"] as! String == reffId })
            self.reffId = reffId
        }
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.constraintTopTextField.constant = self.constraintTopTextField.constant + 50
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
        self.containerPreviewReply.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .secondaryColor
        
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
        titleReply.font = UIFont.systemFont(ofSize: 12).bold
        let idMe = User.getMyPin() as String?
        if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
            titleReply.text = "You".localized()
        } else {
            if self.isContactCenter {
                let user: [User] = self.users.filter({$0.pin == dataMessages[indexPath.row]["f_pin"] as? String})
                titleReply.text = user.first!.fullName
            } else {
                titleReply.text = self.dataPerson["name"]!!
            }
        }
        titleReply.textColor = .orangeColor
        
        let contentReply = UILabel()
        self.containerPreviewReply.addSubview(contentReply)
        contentReply.translatesAutoresizingMaskIntoConstraints = false
        contentReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
        contentReply.topAnchor.constraint(equalTo: titleReply.bottomAnchor).isActive = true
        contentReply.font = UIFont.systemFont(ofSize: 10)
        let message_text = dataMessages[indexPath.row]["message_text"] as! String
        let attachment_flag = dataMessages[indexPath.row]["attachment_flag"] as! String
        let thumb_chat = dataMessages[indexPath.row]["thumb_id"] as! String
        let image_chat = dataMessages[indexPath.row]["image_id"] as! String
        let video_chat = dataMessages[indexPath.row]["video_id"] as! String
        let file_chat = dataMessages[indexPath.row]["file_id"] as! String
        if (attachment_flag == "0" && thumb_chat == "") {
            contentReply.attributedText = message_text.richText()
        } else if (attachment_flag == "1" || image_chat != "") {
            if (message_text == "") {
                contentReply.text = "📷 Photo".localized()
            } else {
                contentReply.attributedText = message_text.richText()
            }
        } else if (attachment_flag == "2" || video_chat != "") {
            if (message_text == "") {
                contentReply.text = "📹 Video".localized()
            } else {
                contentReply.attributedText = message_text.richText()
            }
        } else if (attachment_flag == "6" || file_chat != ""){
            contentReply.text = "📄 \(message_text.components(separatedBy: "|")[0])"
        } else if (attachment_flag == "11") {
            contentReply.text = "❤️ Sticker"
        }
        contentReply.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .gray
        
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
            if (messageTextForSearch[idx]["message_text"] as! String).lowercased().contains(textSearch) {
                lastIndex += 1
                if lastIndex < indexScroll {
                    continue
                }
                lastScrollIdxSearch = lastIndex
                let section = self.dataDates.firstIndex(of: messageTextForSearch[idx]["chat_date"] as! String)
                if section == nil {
                    return
                }
                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[section!]}).firstIndex(where: { $0["message_id"] as? String == messageTextForSearch[idx]["message_id"] as? String})
                if row == nil {
                    return
                }
                let indexPath = IndexPath(row: row!, section: section!)
                self.tableChatView.scrollToRow(at: indexPath, at: .middle, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let cell = self.tableChatView.cellForRow(at: indexPath) {
                        let containerMessage = cell.contentView.subviews[0]
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

extension UITableView {
    
    func scrollToBottom(isAnimated:Bool = true){
        
        DispatchQueue.main.async {
            if self.numberOfSections == 0 {
                return
            }
            let indexPath = IndexPath(
                row: self.numberOfRows(inSection:  self.numberOfSections-1) - 1,
                section: self.numberOfSections - 1)
            if indexPath.row != -1 {
                self.scrollToRow(at: indexPath, at: .bottom, animated: isAnimated)
            }
        }
    }
    
    func scrollToTop(isAnimated:Bool = true) {
        
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: 0, section: 0)
            if indexPath.row != -1 {
                self.scrollToRow(at: indexPath, at: .top, animated: isAnimated)
            }
        }
    }
}

extension UIImage {
    func imageWithInsets(insets: UIEdgeInsets) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: self.size.width + insets.left + insets.right,
                   height: self.size.height + insets.top + insets.bottom), false, self.scale)
        let _ = UIGraphicsGetCurrentContext()
        let origin = CGPoint(x: insets.left, y: insets.top)
        self.draw(at: origin)
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithInsets
    }
}

extension EditorPersonal: UISearchBarDelegate {
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        textSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        countMatchesSearch = 0
        titleSearchMatches.isHidden = true
        tableChatView.reloadData()
        scrollToFirstSearchMessage()
    }
}


public class ObjectGesture: UITapGestureRecognizer {
    public var message_id = ""
    public var image_id = ""
    public var video_id = ""
    public var file_id = ""
    public var imageView = UIImageView()
    public var containerFile = UIView()
    public var labelFile = UILabel()
    public var videoURL: NSURL?
    public var indexPath = IndexPath()
    public var indexImageTapped: Int!
    public var listImageFromGrouping: [ImageGrouping]!
    public var isInitiator: Bool!
}

class navigationQLPreviewDocument: UIBarButtonItem {
    var navigation = UINavigationController()
}

class segmentedControllerObject: UISegmentedControl {
    var navigation = UINavigationController()
}

public class ImageGrouping {
    public var messageId = ""
    public var thumbId = ""
    public var imageId = ""
    public var status = ""
    public var time = ""
    public var lPin = ""
    public var dataMessage: [String: Any?] = [:]
    public var dataPerson: [String: String?] = [:]
    public var dataGroup: [String: Any?] = [:]
    public var dataTopic: [String: Any?] = [:]
    public var isSelected = false
    
    public init(messageId: String, thumbId: String, imageId: String, status: String, time: String, lPin: String, dataMessage: [String: Any?], dataPerson: [String: String?], dataGroup: [String: Any?], dataTopic: [String: Any?]) {
        self.messageId = messageId
        self.thumbId = thumbId
        self.imageId = imageId
        self.status = status
        self.time = time
        self.lPin = lPin
        self.dataMessage = dataMessage
        self.dataPerson = dataPerson
        self.dataGroup = dataGroup
        self.dataTopic = dataTopic
    }
}

public class TypeDataMessage {
    public static let message_id = "message_id"
    public static let f_pin = "f_pin"
    public static let l_pin = "l_pin"
    public static let message_scope_id = "message_scope_id"
    public static let server_date = "server_date"
    public static let status = "status"
    public static let message_text = "message_text"
    public static let audio_id = "audio_id"
    public static let video_id = "video_id"
    public static let image_id = "image_id"
    public static let thumb_id = "thumb_id"
    public static let read_receipts = "read_receipts"
    public static let chat_id = "chat_id"
    public static let file_id = "file_id"
    public static let attachment_flag = "attachment_flag"
    public static let reff_id = "reff_id"
    public static let lock = "lock"
    public static let is_stared = "is_stared"
    public static let blog_id = "blog_id"
    public static let credential = "credential"
    public static let progress = "progress"
    public static let chat_date = "chat_date"
    public static let is_call_center = "is_call_center"
    public static let call_center_id = "call_center_id"
    public static let opposite_pin = "opposite_pin"
    public static let last_edit = "last_edit"
}
