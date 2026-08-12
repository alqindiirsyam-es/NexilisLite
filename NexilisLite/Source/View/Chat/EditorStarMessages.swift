//
//  EditorStarMessages.swift
//  Qmera
//
//  Created by Akhmad Al Qindi Irsyam on 22/09/21.
//

import UIKit
import AVKit
import AVFoundation
import QuickLook
import Photos
import SwiftLinkPreview
import nuSDKService
import NotificationBannerSwift
import SDWebImage

public class EditorStarMessages: UIViewController, UITableViewDataSource, UITableViewDelegate, UIContextMenuInteractionDelegate, QLPreviewControllerDataSource, UITextViewDelegate, AVAudioPlayerDelegate, UIGestureRecognizerDelegate, ChatBubbleContextMenuPresenting {
    @IBOutlet var tableChatView: UITableView!
    var dataMessages: [[String: Any?]] = []
    var dataDates: [String] = []
    var previewItem = NSURL()
    var fromNotification = false
    var timerCheckLink: Timer?
    var showMenuContext = false
    // Fix: state behind ChatBubbleContextMenuPresenting - the WhatsApp-style menu very long
    // bubbles get instead of the system one. Same as EditorGroup.swift.
    var contextMenuActionHandlers: [String: () -> Void] = [:]
    var contextMenuActionSeed = 0
    weak var longBubbleContextMenu: ChatBubbleContextMenu?
    // Fix: mirrors EditorGroup.swift's link-handling state (see its CHANGELOG entries
    // for the full history of why each of these exists).
    private var currentLinkHighlightViews: [UIView] = []
    private var suppressNextLinkTap = false
    private var suppressLinkTapToken = 0
    private var linkPressGeneration = 0
    var touchedSubview = UIView()
    var lastTouchPoint: CGPoint = .zero
    
    var downloadList: [String: IndexPath] = [:]
    var transitioningDelegateRef: ZoomTransitioningDelegate?
    
    var audioPlayers: [IndexPath: AVAudioPlayer] = [:]
    var timers: [IndexPath: Timer] = [:]
    var playingIndexPath: IndexPath?
    var timerSearch: Timer?
    
    func offset() -> CGFloat{
        guard let fontSize = Int(SecureUserDefaults.shared.value(forKey: "font_size") ?? "0") else { return 0 }
        return CGFloat(fontSize)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = UIColor.mainColor
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.topItem?.title = ""
        self.title = "Favorite Messages".localized()
        
        let menu = UIMenu(title: "", children: [
            UIAction(title: "Unfavorite all messages".localized(), handler: {(_) in
                DispatchQueue.global().async {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            _ = Database.shared.updateAllRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                "is_stared" : 0
                            ])
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                }
                self.dataMessages.removeAll()
                self.tableChatView.reloadData()
            }),
        ])
        
        getData()
        
        let moreIcon = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: menu)
        navigationItem.rightBarButtonItem = moreIcon
        navigationItem.rightBarButtonItem?.tintColor = UIColor.secondaryColor
        
        tableChatView.delegate = self
        tableChatView.dataSource = self
        tableChatView.reloadData()
        
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(onRefreshData(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerStatusChat), object: nil)
        center.addObserver(self, selector: #selector(onRefreshData(notification:)), name: NSNotification.Name(rawValue: "listenerStarMessage"), object: nil)
        // Fix: downloads broadcast their progress now, so a file fetched from another
        // screen (or before this one opened) still redraws its row here when it lands.
        center.addObserver(self, selector: #selector(onDownloadChat(notification:)), name: Download.progressNotification, object: nil)

    }
    
    @objc func onRefreshData(notification: NSNotification) {
        DispatchQueue.main.async { [self] in
            getData()
            tableChatView.reloadData()
        }
    }
    
    @objc func didTapExit() {
        self.dismiss(animated: true, completion: nil)
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
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
        return 30
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        dataDates.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = dataMessages.filter({ $0["chat_date"] as! String == dataDates[section] }).count
        return count
    }
    
    @objc func profilePersonTapped(_ sender: ObjectGesture) {
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
            }
        }
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
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let idMe = User.getMyPin() as String?
        let dataMessages = dataMessages.filter({$0["chat_date"]  as? String ?? "" == dataDates[indexPath.section]})
        
        let cellMessage = UITableViewCell()
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
        
        var containerMessage = UIView()
        if (dataMessages[indexPath.row]["credential"] as? String) == "1" && (dataMessages[indexPath.row]["lock"] as? String) != "2" && (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            containerMessage = SecureField().secureContainer!
        }
        let messageIdChat = (dataMessages[indexPath.row]["message_id"] as? String) ?? ""
        let thumbChat = dataMessages[indexPath.row]["thumb_id"]  as? String ?? ""
        let imageChat = dataMessages[indexPath.row]["image_id"]  as? String ?? ""
        let videoChat = dataMessages[indexPath.row]["video_id"]  as? String ?? ""
        let fileChat = dataMessages[indexPath.row]["file_id"]  as? String ?? ""
        let reffChat = dataMessages[indexPath.row]["reff_id"]  as? String ?? ""
        let audioChat = (dataMessages[indexPath.row]["audio_id"] as? String) ?? ""
        let gifChat = (dataMessages[indexPath.row]["gif_id"] as? String) ?? ""
        
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
        // Fix: mirrors EditorGroup.swift's isSelectable = false change - see its
        // CHANGELOG entries for the full history.
        messageText.isSelectable = false
        messageText.dataDetectorTypes = [.link]
        messageText.backgroundColor = .clear
        messageText.isScrollEnabled = false
        messageText.textContainerInset = UIEdgeInsets.zero
        messageText.contentInset = UIEdgeInsets.zero
        messageText.textDragInteraction?.isEnabled = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMessageTextTap(_:)))
        messageText.addGestureRecognizer(tapGesture)

        let touchHighlightGesture = LinkTouchHighlightGesture(target: self, action: #selector(handleLinkTouchHighlight(_:)))
        touchHighlightGesture.minimumPressDuration = 0
        touchHighlightGesture.textView = messageText
        touchHighlightGesture.delegate = self
        touchHighlightGesture.cancelsTouchesInView = false
        touchHighlightGesture.delaysTouchesBegan = false
        messageText.addGestureRecognizer(touchHighlightGesture)

        containerMessage.addSubview(messageText)
        messageText.translatesAutoresizingMaskIntoConstraints = false
        var topMarginText = messageText.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 32)
        
        let dataProfile = getDataProfile(f_pin: dataMessages[indexPath.row]["f_pin"]  as? String ?? "")
        
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
            profileMessage.leadingAnchor.constraint(equalTo: cellMessage.contentView.leadingAnchor, constant: 15).isActive = true
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
            
            profileMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 5).isActive = true
            containerMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 5).isActive = true
            
            containerMessage.leadingAnchor.constraint(equalTo: profileMessage.trailingAnchor, constant: 5).isActive = true
            containerMessage.trailingAnchor.constraint(lessThanOrEqualTo: cellMessage.contentView.trailingAnchor, constant: -60).isActive = true
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            if dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"]as? String == "" {
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
        if dataMessages[indexPath.row]["is_stared"] as? String == "1" {
            cellMessage.contentView.addSubview(imageStared)
            imageStared.translatesAutoresizingMaskIntoConstraints = false
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                imageStared.bottomAnchor.constraint(equalTo: timeMessage.topAnchor).isActive = true
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
                imageSpecFileView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 30).isActive = true
            } else {
                imageSpecFileView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -30).isActive = true
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
            else if attachmentFlag == "11" {
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
                messageText.attributedText = textChat.richText()
                modifyText(at: indexPath)
            }
        } else {
            messageText.attributedText = textChat.richText()
            modifyText(at: indexPath)
        }
        
        func modifyText(at indexPath: IndexPath) {
            guard !textChat.isEmpty else { return }
            guard indexPath.row >= 0, indexPath.row < dataMessages.count else {
                print("⚠️ modifyText: Invalid index \(indexPath.row), total: \(dataMessages.count)")
                return
            }

            var text = textChat
            let messageData = dataMessages[indexPath.row]

            // Remove segment after separator
            if let separatorRange = text.range(of: "■") {
                text = String(text[..<separatorRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Optional pipe-split logic
            if !fileChat.isEmpty {
                let lock = messageData["lock"] as? String ?? ""
                if lock != "1", lock != "2" {
                    let parts = text.components(separatedBy: "|")
                    if parts.count > 1 { text = parts[1] }
                }
            }

            // Must be mutable!
            let finalAttributed = NSMutableAttributedString(attributedString: text.richText())

            let urlPattern = "(https?://|www\\.)\\S+"
            guard let regex = try? NSRegularExpression(pattern: urlPattern) else { return }

            let fullString = finalAttributed.string
            let fullLength = (fullString as NSString).length

            let matches = regex.matches(in: fullString, range: NSRange(location: 0, length: fullLength))

            for match in matches {
                let range = match.range

                // Skip invalid ranges safely
                if range.location == NSNotFound ||
                   range.location + range.length > fullLength ||
                   range.length == 0 {
                    continue
                }

                let linkText = (fullString as NSString).substring(with: range)

                finalAttributed.addAttributes([
                    .link: linkText,
                    .foregroundColor: UIColor.systemBlue,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ], range: range)
            }

            messageText.attributedText = finalAttributed
            messageText.delegate = self
        }
        
        let interaction = UIContextMenuInteraction(delegate: self)
        containerMessage.addInteraction(interaction)
        containerMessage.isUserInteractionEnabled = true
        
//        if isSearching && textSearch.count > 1 && dataMessages[indexPath.row][TypeDataMessage.attachment_flag] as? String != "11" {
//            messageText.attributedText = textChat.richText(isSearching: true, textSearch: textSearch, group_id: self.dataGroup["group_id"]  as? String ?? "")
//        }
        
        let stringDate = (dataMessages[indexPath.row]["server_date"]  as? String ?? "")
        if !stringDate.isEmpty {
            let date = Date(milliseconds: Int64(stringDate) ?? 100)
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
            timeMessage.text = formatter.string(from: date as Date)
            timeMessage.textColor = .lightGray
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
            var padTop: CGFloat = 32
            if dataMessages[indexPath.row][TypeDataMessage.is_forwarded] != nil && dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as! Int != 0 {
                padTop = 52
            }
            
            let contAudio = UIView()
            contAudio.backgroundColor = .clear
            containerMessage.addSubview(contAudio)
            contAudio.anchor(top: containerMessage.topAnchor, left: containerMessage.leftAnchor, bottom: containerMessage.bottomAnchor, right: containerMessage.rightAnchor, paddingTop: padTop, paddingLeft: 15, paddingBottom: 15, paddingRight: 15)
            
            let imageAudio = UIImageView()
            imageAudio.image = UIImage(systemName: "music.note", withConfiguration: UIImage.SymbolConfiguration(pointSize: 35))
            contAudio.addSubview(imageAudio)
            imageAudio.anchor(top: contAudio.topAnchor, left: contAudio.leftAnchor, bottom: contAudio.bottomAnchor, centerY: contAudio.centerYAnchor)
            imageAudio.tintColor = .mainColor
            
            let playButtonAudio = UIButton(type: .system)
            playButtonAudio.setImage(UIImage(systemName: "play.fill"), for: .normal)
            playButtonAudio.tintColor = .gray
            contAudio.addSubview(playButtonAudio)
            playButtonAudio.anchor(left: contAudio.leftAnchor, paddingLeft: 45, centerY: contAudio.centerYAnchor, width: 20, height: 20)
            
            let progressSliderAudio = UISlider()
            progressSliderAudio.minimumValue = 0
            progressSliderAudio.maximumValue = 1
            let thumbImage = UIImage(systemName: "circle.fill")?.withTintColor(UIColor.mainColor)
                .resize(target: CGSize(width: 15, height: 15))
            progressSliderAudio.setThumbImage(thumbImage, for: .normal)
            contAudio.addSubview(progressSliderAudio)
            progressSliderAudio.anchor(left: playButtonAudio.rightAnchor, right: contAudio.rightAnchor, paddingLeft: 10, centerY: contAudio.centerYAnchor, height: 15)
            
            let timeLabelAudio = UILabel()
            timeLabelAudio.text = "0:00"
            timeLabelAudio.font = .systemFont(ofSize: 10 + offset())
            timeLabelAudio.textColor = .gray
            contAudio.addSubview(timeLabelAudio)
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
                    // Fix: cellForRow runs again on every scroll pass, and each pass used to hand the
                    // same file another completion to call - dozens of them by the time a transfer
                    // finished, every one of them reloading the same row. The transfer that is already
                    // running keeps the row up to date by itself now (see onDownloadChat).
                    if !Download.isDownloading(forKey: audioChat) {
                        Download().startHTTP(forKey: audioChat) { [weak self] (name, progress) in
                            guard progress == 100 else {
                                return
                            }
                            // Fix: was reloadRows(at: [indexPath]) against the table captured while the
                            // cell was being built - by the time a download finishes, that index path may
                            // belong to another message, or to no row at all.
                            DispatchQueue.main.async {
                                self?.reloadMessageRow(withFileNamed: name)
                            }
                        }
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
                                let tempPath = cachesDirectory.appendingPathComponent(audioChat.contains(".aac") ? "\(audioChat.components(separatedBy: ".")[0]).m4a" : audioChat)
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
            let getHeightImage = ListGroupImages.getImageSize(image: thumbChat, screenWidth: self.view.frame.size.width * 0.6, screenHeight: 305).height
            let getWidthImage = ListGroupImages.getImageSize(image: thumbChat, screenWidth: self.view.frame.size.width * 0.6, screenHeight: 305).width
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
                    // Fix: cellForRow runs again on every scroll pass, and each pass used to hand the
                    // same file another completion to call - dozens of them by the time a transfer
                    // finished, every one of them reloading the same row. The transfer that is already
                    // running keeps the row up to date by itself now (see onDownloadChat).
                    if !Download.isDownloading(forKey: thumbChat) {
                        Download().startHTTP(forKey: thumbChat) { [weak self] (name, progress) in
                            guard progress == 100 else {
                                return
                            }
                            // Fix: was reloadRows(at: [indexPath]) against the table captured while the
                            // cell was being built - by the time a download finishes, that index path may
                            // belong to another message, or to no row at all.
                            DispatchQueue.main.async {
                                self?.reloadMessageRow(withFileNamed: name)
                            }
                        }
                    }
                }
                
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(imageChat)
                if !FileManager.default.fileExists(atPath: imageURL.path) && !FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
                    let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
                    let blurEffectView = UIVisualEffectView(effect: blurEffect)
                    blurEffectView.frame = CGRect(x: 0, y: 0, width: imageThumb.frame.size.width, height: imageThumb.frame.size.height)
                    blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    imageThumb.addSubview(blurEffectView)
                    // Fix: while the image is actually downloading the progress ring stands in for
                    // this button - they are both centred on the thumbnail and would overlap.
                    if !imageChat.isEmpty, !Download.isDownloading(forKey: imageChat) {
                        let imageDownload = UIImageView(image: UIImage(systemName: "arrow.down.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .default)))
                        imageThumb.addSubview(blurEffectView)
                        imageThumb.addSubview(imageDownload)
                        imageDownload.tintColor = .black.withAlphaComponent(0.3)
                        imageDownload.translatesAutoresizingMaskIntoConstraints = false
                        imageDownload.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                        imageDownload.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                    }
                } else if (dataMessages[indexPath.row]["credential"] as? String) == "1" && (dataMessages[indexPath.row]["lock"] as? String) != "2" && (dataMessages[indexPath.row]["lock"] as? String) != "1" {
                    let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
                    let blurEffectView = UIVisualEffectView(effect: blurEffect)
                    blurEffectView.frame = CGRect(x: 0, y: 0, width: imageThumb.frame.size.width, height: imageThumb.frame.size.height)
                    blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    imageThumb.addSubview(blurEffectView)
                }
                
            }
            
            // Fix: same for the play button - the ring replaces it for as long as the video
            // is being fetched.
            if videoChat != "" && gifChat.isEmpty && !Download.isDownloading(forKey: videoChat) {
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
                        // Fix: cellForRow runs again on every scroll pass, and each pass used to hand the
                        // same file another completion to call - dozens of them by the time a transfer
                        // finished, every one of them reloading the same row. The transfer that is already
                        // running keeps the row up to date by itself now (see onDownloadChat).
                        if !Download.isDownloading(forKey: gifChat) {
                            Download().startHTTP(forKey: gifChat) { [weak self] (name, progress) in
                                guard progress == 100 else {
                                    return
                                }
                                // Fix: was reloadRows(at: [indexPath]) against the table captured while the
                                // cell was being built - by the time a download finishes, that index path may
                                // belong to another message, or to no row at all.
                                DispatchQueue.main.async {
                                    self?.reloadMessageRow(withFileNamed: name)
                                }
                            }
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
                // Fix: the same caption as the download ring - how much of the file has gone up
                // so far, out of how much there is (TransferBytes, filled in by Network).
                let uploadingChat = !videoChat.isEmpty ? videoChat : imageChat
                let uploadChip = ChatTransferRing.addSizeLabel(to: imageThumb, fileName: uploadingChat)
                NSLayoutConstraint.activate([
                    uploadChip.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                    uploadChip.leadingAnchor.constraint(equalTo: container.trailingAnchor, constant: 6)
                ])
            }
            
            // Fix: the download ring is drawn from here now, not built by hand in
            // contentMessageTapped - so it survives the cell being recycled, and shows up
            // by itself on a transfer that was already running when this screen opened.
            let downloadingChat = !videoChat.isEmpty ? videoChat : imageChat
            if !downloadingChat.isEmpty, Download.isDownloading(forKey: downloadingChat) {
                ChatTransferRing.add(to: imageThumb, fileName: downloadingChat, progress: Download.progress(forKey: downloadingChat) ?? 0)
            }
            
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
                // Fix: the ring on a file bubble says how far along it is in bytes now, the
                // same as the one on photos and videos. It hangs under the file name, which
                // stays put - so a file that is merely not downloaded yet looks exactly as it
                // always did, and the caption only takes up room once there is a size to show.
                let transferSizeChip = ChatTransferRing.addSizeLabel(to: containerViewFile, fileName: fileChat, chromeless: true)
                NSLayoutConstraint.activate([
                    transferSizeChip.topAnchor.constraint(equalTo: nameFile.bottomAnchor, constant: 2),
                    transferSizeChip.leadingAnchor.constraint(equalTo: nameFile.leadingAnchor)
                ])
            } else {
                nameFile.trailingAnchor.constraint(equalTo: containerViewFile.trailingAnchor, constant: -5).isActive = true
            }
            
            let objectTap = ObjectGesture(target: self, action: #selector(contentMessageTapped(_:)))
            let sfs = (dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String) ?? ""
            containerViewFile.addGestureRecognizer(objectTap)
            objectTap.containerFile = containerViewFile
            objectTap.labelFile = nameFile
            objectTap.file_id = fileChat
            objectTap.specFile = sfs
            objectTap.indexPath = indexPath
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
                        
                        let objectTap = ObjectGesture(target: self, action: #selector(tapMessageText(_:)))
                        objectTap.message_id = text
                        containerLinkMessage.addGestureRecognizer(objectTap)
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
                    let sessionDelegate = PinnedURLSessionNexilisDelegate()
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
                        let dataProfile = getDataProfile(f_pin: data["f_pin"]  as? String ?? "")
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
                    contentReply.attributedText = message_text.richText()
                } else if (attachment_flag == "1" || image_chat != "") {
                    if (message_text.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                        contentReply.text = "📷 Photo".localized()
                    } else {
                        contentReply.attributedText = message_text.richText()
                    }
                } else if (attachment_flag == "2" || video_chat != "") {
                    if (message_text.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                        contentReply.text = "📹 Video".localized()
                    } else {
                        contentReply.attributedText = message_text.richText()
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
                
                let objectTap = ObjectGesture(target: self, action: #selector(contentMessageTapped(_:)))
                containerReply.addGestureRecognizer(objectTap)
                objectTap.indexPath = indexPath
                objectTap.message_id = data["message_id"]  as? String ?? ""
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
            if fileChat != "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1") {
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
    
    @objc func tapAck(_ sender: ObjectGesture) {
        let indexPath = sender.indexPath
        let dataMessages = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == dataDates[indexPath.section]})
        if dataMessages[indexPath.row]["status"]  as? String ?? "" == "8" {
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
            let result = Nexilis.write(message: CoreMessage_TMessageBank.getAckLocationMessage(f_pin: dataMessages[indexPath.row]["f_pin"]  as? String ?? "", message_id: dataMessages[indexPath.row]["message_id"]  as? String ?? "", l_pin: dataMessages[indexPath.row]["l_pin"]  as? String ?? "", server_date: "\(Date().currentTimeMillis())", message_scope_id: dataMessages[indexPath.row]["message_scope_id"]  as? String ?? "", longitude: "", latitude: "", description: ""))
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
        
    // Fix: delegates to LinkOpener.swift - the single shared, corrected
    // implementation also used by EditorGroup, EditorStarMessages, ChatGPTBotView,
    // and MessageInfo. See LinkOpener.swift for the full list of bugs fixed
    // (broken custom instagram://twitter://youtube:// deep links that "succeeded"
    // but always landed on the app's home screen instead of the tapped content).
    @objc func tapMessageText(_ sender: ObjectGesture) {
        LinkOpener.open(urlString: sender.message_id)
    }
    
    func getData() {
        if !dataMessages.isEmpty {
            dataMessages.removeAll()
        }
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared, blog_id, attachment_speciality FROM MESSAGE where is_stared=1 order by server_date asc") {
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
                        row[TypeDataMessage.spec_file] = cursorData.string(forColumnIndex: 19)
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
                        row["chat_date"] = chatDate(stringDate: row["server_date"] as! String, messageId: row["message_id"] as! String)
                        dataMessages.append(row)
                    }
                    cursorData.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    private func chatDate(stringDate: String, messageId: String) -> String {
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
                imageViewer.media = .gif(data ?? Data())
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
            
            let name = "Favorite Messages".localized()
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
                    // Fix: this used to put a spinner of its own on the bubble. The progress ring
                    // cellForRow draws does that job now - for images as well as videos - so all this
                    // has left to do is redraw the row once the file is here.
                    Download().startHTTP(forKey: sender.image_id) { [weak self] (name, progress) in
                        guard progress >= 100 || progress < 0 else {
                            return
                        }
                        DispatchQueue.main.async {
                            self?.tableChatView.reloadData()
                        }
                    }
                    // Draw the row again so the ring appears straight away, at whatever progress the
                    // transfer is already at.
                    reloadMessageRow(withFileNamed: sender.image_id)
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
                    // Fix: this used to build a progress ring by hand, onto the one cell instance that
                    // had been tapped - lost the moment that cell was recycled. cellForRow draws it now,
                    // and onDownloadChat moves it, so this only has to start the transfer.
                    Download().startHTTP(forKey: sender.video_id) { [weak self] (name, progress) in
                        guard progress >= 100 || progress < 0 else {
                            return
                        }
                        DispatchQueue.main.async {
                            guard let self = self else {
                                return
                            }
                            // A download that failed used to stay in downloadList forever, and the guard
                            // above this call then swallowed every retry.
                            self.downloadList.removeValue(forKey: name)
                            if progress >= 100, let idx = self.dataMessages.firstIndex(where: { $0["video_id"] as? String ?? "" == name }) {
                                self.dataMessages[idx]["progress"] = 100.0
                            }
                            self.reloadMessageRow(withFileNamed: name)
                        }
                    }
                    // Draw the row again so the ring appears straight away, at whatever progress the
                    // transfer is already at.
                    reloadMessageRow(withFileNamed: sender.video_id)
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
                    // Fix: this also compared the index path, so the same file could be started
                    // again from a row that had shifted, stacking a second progress ring on the
                    // bubble. All that matters is whether this screen is already following it.
                    if downloadList[sender.file_id] != nil {
                        return
                    }
                    downloadList[sender.file_id] = sender.indexPath
                    // Fix: this used to build a progress ring by hand, onto the one cell instance that
                    // had been tapped - lost the moment that cell was recycled. cellForRow draws it now,
                    // and onDownloadChat moves it, so this only has to start the transfer.
                    Download().startHTTP(forKey: sender.file_id) { [weak self] (name, progress) in
                        guard progress >= 100 || progress < 0 else {
                            return
                        }
                        DispatchQueue.main.async {
                            guard let self = self else {
                                return
                            }
                            // A download that failed used to stay in downloadList forever, and the guard
                            // above this call then swallowed every retry.
                            self.downloadList.removeValue(forKey: name)
                            if progress >= 100, let idx = self.dataMessages.firstIndex(where: { $0["file_id"] as? String ?? "" == name }) {
                                self.dataMessages[idx]["progress"] = 100.0
                            }
                            self.reloadMessageRow(withFileNamed: name)
                        }
                    }
                    // Draw the row again so the ring appears straight away, at whatever progress the
                    // transfer is already at.
                    reloadMessageRow(withFileNamed: sender.file_id)
                }
            }
        } else {
            DispatchQueue.main.async {
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == sender.message_id})
                if idx == nil {
                    return
                }
                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                if section == nil {
                    return
                }
                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[section!]}).firstIndex(where: { $0["message_id"] as! String == self.dataMessages[idx!]["message_id"] as! String})
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
                            containerMessage.backgroundColor = .mainColor.withAlphaComponent(0.3)
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
    
    func getDataProfile(f_pin: String) -> [String: String]{
        var data: [String: String] = [:]
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || last_name, image_id from BUDDY where f_pin = '\(f_pin)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0)!.trimmingCharacters(in: .whitespacesAndNewlines)
                data["image_id"] = c.string(forColumnIndex: 1)!
                c.close()
            }
            else if f_pin == "-999" {
                data["name"] = "Bot".localized()
                data["image_id"] = "pb_powered"
            }
            else {
                data["name"] = "Unknown".localized()
                data["image_id"] = ""
            }
        })
        return data
    }
    
    private func getDataProfileFromMessageId(message_id: String) -> [String: String]{
        var data: [String: String] = [:]
        Database.shared.database?.inTransaction({ fmdb, rollback in
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
    
    @objc func onDownloadChat(notification: NSNotification) {
        guard let name = notification.userInfo?["name"] as? String,
              let progress = notification.userInfo?["progress"] as? Double,
              progress >= 0 else {
            return
        }
        if progress >= 100 {
            reloadMessageRow(withFileNamed: name)
            return
        }
        // Moves the ring cellForRow drew, on whatever cell is showing the message now.
        guard let indexPath = indexPathForMessage(withFileNamed: name),
              let cell = tableChatView.cellForRow(at: indexPath) else {
            return
        }
        ChatTransferRing.updateSizeText(forFileNamed: name, in: cell)
        ChatTransferRing.setProgress(progress, in: cell)
    }

    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        // The menu is going away and its UIActions own their handlers anyway - keeping the
        // duplicates here would just be a strong reference back to self that outlives it.
        contextMenuActionHandlers.removeAll()
        if showMenuContext {
            showMenuContext = false
            interaction.view!.removeInteraction(interaction)
        }
    }
    
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        // Fix: mirrors EditorGroup.swift - suppresses the bubble-wide Unstar menu
        // when the touch is on a link, leaving it to handleLinkTouchHighlight's own
        // timer instead. See EditorGroup.swift's CHANGELOG entries for the full
        // history.
        if LinkHighlighting.linkHit(at: location, in: interaction.view) != nil {
            return nil
        }

        // Fix: these closures capture self strongly (they always have - they're the very
        // same closures that used to go straight into UIAction), so the ones registered
        // by the previous long-press are dropped here rather than piling up on self.
        contextMenuActionHandlers.removeAll()
        let indexPath = self.tableChatView.indexPathForRow(at: interaction.view!.convert(location, to: self.tableChatView))
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath!.section]})
        let star = chatMenuAction(title: "Unstar".localized(), image: UIImage(systemName: "star.slash.fill"), handler: {(_) in
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
            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == dataMessages[indexPath!.row]["message_id"] as! String})
            if idx != nil{
                self.dataMessages[idx!]["is_stared"] = "0"
            }
            self.dataMessages.remove(at: idx!)
            self.tableChatView.deleteRows(at: [indexPath!], with: .fade)
            if self.dataMessages.filter({ $0["chat_date"] as! String == dataMessages[indexPath!.row]["chat_date"] as! String }).count == 0 {
                self.dataDates.remove(at: indexPath!.section)
                self.tableChatView.deleteSections(IndexSet(integer: indexPath!.section), with: .fade)
            }
            self.tableChatView.reloadData()
        })
        let forward = chatMenuAction(title: "Forward".localized(), image: UIImage(systemName: "arrowshape.turn.up.right.fill"), handler: {(_) in
            let navigationController = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactChatNav") as! UINavigationController
            Utils.addBackground(view: navigationController.view)
            navigationController.modalPresentationStyle = .custom
            navigationController.navigationBar.tintColor = .white
            navigationController.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.overrideUserInterfaceStyle = .dark
            navigationController.navigationBar.barStyle = .black
            let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
            UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
            let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
            navigationController.navigationBar.titleTextAttributes = textAttributes
            if let controller = navigationController.viewControllers.first as? ContactChatViewController {
                controller.isChooser = { [weak self] scope, pin in
                    if scope == "3" {
                        let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                        editorPersonalVC.unique_l_pin = pin
                        editorPersonalVC.dataMessageForward = [dataMessages[indexPath!.row]]
                        self?.navigationController?.replaceAllViewController(with: editorPersonalVC, animated: true)
                    } else {
                        let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                        editorGroupVC.unique_l_pin = pin
                        editorGroupVC.dataMessageForward = [dataMessages[indexPath!.row]]
                        self?.navigationController?.replaceAllViewController(with: editorGroupVC, animated: true)
                    }
                }
            }
            self.present(navigationController, animated: true, completion: nil)
        })
        let copy = chatMenuAction(title: "Copy".localized(), image: UIImage(systemName: "doc.on.doc.fill"), handler: {(_) in
            if (dataMessages[indexPath!.row]["attachment_flag"] as! String == "0") {
                DispatchQueue.main.async {
                    var text = ""
                    let stringDate = (dataMessages[indexPath!.row]["server_date"] as! String)
                    let date = Date(milliseconds: Int64(stringDate)!)
                    let formatterDate = DateFormatter()
                    let formatterTime = DateFormatter()
                    formatterDate.dateFormat = "dd/MM/yy"
                    formatterDate.locale = NSLocale(localeIdentifier: "id") as Locale?
                    formatterTime.dateFormat = "HH:mm"
                    formatterTime.locale = NSLocale(localeIdentifier: "id") as Locale?
                    let dataProfile = self.getDataProfileFromMessageId(message_id: dataMessages[indexPath!.row]["message_id"] as! String)
                    if text.isEmpty {
                        text = "*[\(formatterDate.string(from: date as Date)) \(formatterTime.string(from: date as Date))] \(dataProfile["name"]!):*\n\(dataMessages[indexPath!.row]["message_text"] as! String)"
                    } else {
                        text = text + "\n\n*[\(formatterDate.string(from: date as Date)) \(formatterTime.string(from: date as Date))] \(dataProfile["name"]!):*\n\(dataMessages[indexPath!.row]["message_text"] as! String)"
                    }
                    text = text + "\n\n\nchat " + "Powered by Nexilis".localized()
                    DispatchQueue.main.async {
                        UIPasteboard.general.string = text
                        self.view.makeToast("Text coppied to clipboard".localized(), duration: 3)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if let dirPath = paths.first {
                        let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(dataMessages[indexPath!.row]["image_id"] as! String)
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
                                    let image    = UIImage(data: imageData)
                                    UIPasteboard.general.image = image
                                    self.view.makeToast("Image coppied to clipboard".localized(), duration: 3)
                                }
                            } catch {
                                
                            }
                            
                        }
                    }
                }
            }
        })
        
        var children: [UIMenuElement] = [star, copy]
        if self.dataMessages[indexPath!.row]["f_pin"] as! String == "-999" || !(dataMessages[indexPath!.row]["image_id"] as! String).isEmpty || !(dataMessages[indexPath!.row]["video_id"] as! String).isEmpty || !(dataMessages[indexPath!.row]["file_id"] as! String).isEmpty || dataMessages[indexPath!.row]["attachment_flag"] as! String == "11" {
            children = [star]
        }
        if (Nexilis.checkingAccess(key: "secure_folder_forward") || (dataMessages[indexPath!.row][TypeDataMessage.spec_file] as? String ?? "").contains("forward")) && self.dataMessages[indexPath!.row]["f_pin"] as! String != "-999" && dataMessages[indexPath!.row]["read_receipts"] as? String != "8" {
            children.insert(forward, at: 1)
        }
        
        // Fix: the menu is ours, not UIKit's - see presentBubbleContextMenu(for:elements:).
        if let bubble = interaction.view,
           presentBubbleContextMenu(for: bubble, elements: children) {
            return nil
        }
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { _ in
            UIMenu(title: "", children: children)
        }
    }
    
    private func copyOption(indexPath: IndexPath) -> UIMenu {
        let ratingButtonTitles = ["Text".localized(), "Image".localized()]
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath.section]})
        let copyActions = ratingButtonTitles
            .enumerated()
            .map { index, title in
                return UIAction(
                    title: title,
                    identifier: nil,
                    handler: {(_) in if (index == 0) {
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
                                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(dataMessages[indexPath.row]["image_id"] as! String)
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
                                            let image    = UIImage(data: imageData)
                                            UIPasteboard.general.image = image
                                            self.view.makeToast("Image coppied to clipboard".localized(), duration: 3)
                                        }
                                    } catch {
                                        
                                    }
                                    
                                }
                            }
                        }
                    }})
            }
        return UIMenu(
            title: "Copy".localized(),
            image: UIImage(systemName: "doc.on.doc.fill"),
            children: copyActions)
    }
    
    @objc private func cancelDocumentPreview(sender: navigationQLPreviewDocument) {
        sender.navigation.dismiss(animated: true, completion: nil)
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
    
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.previewItem as QLPreviewItem
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dataMessages = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == dataDates[indexPath.section]})
        let message = dataMessages[indexPath.row]
        if let attachmentFlag = message["attachment_flag"], let attachmentFlag = attachmentFlag as? String {
            if attachmentFlag == "27" {
                if !Nexilis.checkingAccess(key: "live_streaming") {
                    if Nexilis.checkingAccessAlert(key: "live_streaming") != "|" && !Nexilis.checkingAccessAlert(key: "live_streaming").isEmpty {
                        let title = Nexilis.checkingAccessAlert(key: "live_streaming").components(separatedBy: "|")[0]
                        let message = Nexilis.checkingAccessAlert(key: "live_streaming").components(separatedBy: "|")[1]
                        APIS.nexilisShowAlertWithHTMLMessage(on: UIApplication.shared.visibleViewController ?? UIViewController(), title: title, message: message)
                    } else {
                        UIApplication.shared.visibleViewController?.view.makeToast("Feature disabled".localized(), duration: 5)
                    }
                    return
                }
                let streamingController = QmeraCreateStreamingViewController()
                streamingController.isJoin = true
                if let messageText = message["message_text"],
                   let messageText = messageText as? String,
                   var json = try! JSONSerialization.jsonObject(with: messageText.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                    if json["blog"] == nil {
                        json["blog"] = message["blog_id"] ?? nil
                    }
                    streamingController.data = json
                }
                let streamingNav = CustomNavigationController(rootViewController: streamingController)
                streamingNav.modalPresentationStyle = .custom
                streamingNav.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
                streamingNav.navigationBar.tintColor = .white
                let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                streamingNav.navigationBar.titleTextAttributes = textAttributes
                streamingNav.navigationBar.isTranslucent = false
                navigationController?.present(streamingNav, animated: true, completion: nil)
            } else if attachmentFlag == "25" {
                if !Nexilis.checkingAccess(key: "vconf_room") {
                    if Nexilis.checkingAccessAlert(key: "vconf_room") != "|" && !Nexilis.checkingAccessAlert(key: "vconf_room").isEmpty {
                        let title = Nexilis.checkingAccessAlert(key: "vconf_room").components(separatedBy: "|")[0]
                        let message = Nexilis.checkingAccessAlert(key: "vconf_room").components(separatedBy: "|")[1]
                        APIS.nexilisShowAlertWithHTMLMessage(on: UIApplication.shared.visibleViewController ?? UIViewController(), title: title, message: message)
                    } else {
                        UIApplication.shared.visibleViewController?.view.makeToast("Feature disabled".localized(), duration: 5)
                    }
                    return
                }
                let conferenceController = CreateSeminarViewController()
                if let messageText = message["message_text"],
                   let messageText = messageText as? String,
                   var json = try! JSONSerialization.jsonObject(with: messageText.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                    if json["blog"] == nil {
                        json["blog"] = message["blog"] ?? nil
                    }
                    if json["members"] == nil {
                        json["members"] = message["members"] ?? nil
                    }
                    if json["by"] as? String != User.getMyPin() as String? {
                        conferenceController.isJoin = true
                    }
                    let start = json["time"] as? Int64 ?? 0
                    json["start"] = String(Date(milliseconds: start).format(dateFormat: "dd/MM/yyyy HH:mm"))
                    conferenceController.data = json
                }
                let conferenceNav = CustomNavigationController(rootViewController: conferenceController)
                conferenceNav.modalPresentationStyle = .custom
                conferenceNav.navigationBar.tintColor = .white
                conferenceNav.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
                conferenceNav.navigationBar.isTranslucent = false
                conferenceNav.navigationBar.overrideUserInterfaceStyle = .dark
                conferenceNav.navigationBar.barStyle = .black
                let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
                UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
                let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                conferenceNav.navigationBar.titleTextAttributes = textAttributes
                conferenceNav.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
                conferenceNav.navigationBar.isTranslucent = false
                navigationController?.present(conferenceNav, animated: true, completion: nil)
            }
        }
        if message[TypeDataMessage.message_scope_id] as? String == "3" {
            var pin = message[TypeDataMessage.l_pin] as? String ?? ""
            if pin == (User.getMyPin() ?? "") {
                pin = message[TypeDataMessage.f_pin] as? String ?? ""
            }
            let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
            editorPersonalVC.hidesBottomBarWhenPushed = true
            editorPersonalVC.unique_l_pin = pin
            editorPersonalVC.referenceMessageId = message[TypeDataMessage.message_id] as? String ?? ""
            editorPersonalVC.referenceChatDate = message[TypeDataMessage.chat_date] as? String ?? ""
            navigationController?.show(editorPersonalVC, sender: nil)
        } else {
            var pin = message[TypeDataMessage.chat_id] as? String ?? ""
            if pin.isEmpty {
                pin = message[TypeDataMessage.l_pin] as? String ?? ""
            }
            let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
            editorGroupVC.hidesBottomBarWhenPushed = true
            editorGroupVC.unique_l_pin = pin
            editorGroupVC.referenceMessageId = message[TypeDataMessage.message_id] as? String ?? ""
            editorGroupVC.referenceChatDate = message[TypeDataMessage.chat_date] as? String ?? ""
            navigationController?.show(editorGroupVC, sender: nil)
        }
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

        // Fix: mirrors EditorGroup.swift's link handling (see its CHANGELOG entries
        // for the full history). With messageText.isSelectable = false, this delegate
        // method no longer fires at all - left in place as a defensive fallback only.
        // Real logic: handleMessageTextTap(_:) (taps) and
        // contextMenuInteraction(_:configurationForMenuAtLocation:) + handleLinkTouchHighlight(_:)
        // (long-press).
        switch interaction {
        case .invokeDefaultAction:
            showLinkHighlight(range: characterRange, in: textView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.hideLinkHighlight()
            }
            LinkOpener.open(urlString: finalURL)
            return false

        case .presentActions:
            return false

        case .preview:
            return false

        @unknown default:
            return true
        }
    }

    // MARK: - Link popup/highlight glue (mirrors EditorGroup.swift - see its
    // CHANGELOG entries for the full history of why this code is shaped this way)

    private func presentLinkActionSheet(urlString: String, sourceView: UIView, sourceRect: CGRect) {
        let openAction: () -> Void = { [weak self] in
            let gesture = ObjectGesture()
            gesture.message_id = urlString
            self?.tapMessageText(gesture)
        }
        let copyAction: () -> Void = { [weak self] in
            UIPasteboard.general.string = urlString
            self?.view.makeToast("Link Copied".localized(), duration: 3)
        }
        let chromeOpenURL = LinkHighlighting.chromeURL(for: urlString)
        let chromeInstalled = chromeOpenURL.map { UIApplication.shared.canOpenURL($0) } ?? false
        let openInChromeAction: (() -> Void)? = chromeInstalled ? { [weak self] in
            guard let chromeOpenURL = chromeOpenURL else { return }
            UIApplication.shared.open(chromeOpenURL, options: [:]) { success in
                if !success {
                    let gesture = ObjectGesture()
                    gesture.message_id = urlString
                    self?.tapMessageText(gesture)
                }
            }
        } : nil

        if #available(iOS 15.0, *) {
            let sheetVC = LinkActionSheetViewController(urlString: urlString, onOpen: openAction, onCopy: copyAction, onOpenInChrome: openInChromeAction)
            sheetVC.onDismissed = { [weak self] in self?.hideLinkHighlight() }

            if let sheet = sheetVC.sheetPresentationController {
                if #available(iOS 16.0, *) {
                    let contentHeight = sheetVC.preferredContentHeight(forWidth: self.view.bounds.width)
                    sheet.detents = [.custom(resolver: { _ in contentHeight })]
                } else {
                    sheet.detents = [.medium()]
                }
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 16
            }
            present(sheetVC, animated: true)
        } else {
            let alert = UIAlertController(title: nil, message: urlString, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Open Link".localized(), style: .default) { [weak self] _ in
                self?.hideLinkHighlight()
                openAction()
            })
            if let openInChromeAction = openInChromeAction {
                alert.addAction(UIAlertAction(title: "Open in Chrome".localized(), style: .default) { [weak self] _ in
                    self?.hideLinkHighlight()
                    openInChromeAction()
                })
            }
            alert.addAction(UIAlertAction(title: "Copy".localized(), style: .default) { [weak self] _ in
                self?.hideLinkHighlight()
                copyAction()
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel) { [weak self] _ in
                self?.hideLinkHighlight()
            })
            if let popover = alert.popoverPresentationController {
                popover.sourceView = sourceView
                popover.sourceRect = sourceRect
            }
            present(alert, animated: true)
        }
    }

    private func showLinkHighlight(range: NSRange, in textView: UITextView) {
        hideLinkHighlight()
        for rect in LinkHighlighting.highlightRects(for: range, in: textView) {
            guard rect.width > 0, rect.height > 0 else { continue }
            let chip = UIView(frame: rect.insetBy(dx: -2, dy: -1))
            chip.backgroundColor = UIColor.systemGray.withAlphaComponent(0.35)
            chip.layer.cornerRadius = 4
            chip.isUserInteractionEnabled = false
            textView.addSubview(chip)
            currentLinkHighlightViews.append(chip)
        }
    }

    private func hideLinkHighlight() {
        for chip in currentLinkHighlightViews {
            chip.removeFromSuperview()
        }
        currentLinkHighlightViews.removeAll()
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is LinkTouchHighlightGesture || otherGestureRecognizer is LinkTouchHighlightGesture {
            return true
        }
        return false
    }

    @objc private func handleLinkTouchHighlight(_ sender: LinkTouchHighlightGesture) {
        guard let textView = sender.textView else { return }
        let point = sender.location(in: textView)

        switch sender.state {
        case .began:
            guard let info = LinkHighlighting.linkInfo(at: point, in: textView) else { return }
            showLinkHighlight(range: info.range, in: textView)

            linkPressGeneration += 1
            let thisGeneration = linkPressGeneration
            let urlString = info.urlString
            let range = info.range
            DispatchQueue.main.asyncAfter(deadline: .now() + LinkHighlighting.longPressThreshold) { [weak self, weak textView] in
                guard let self = self, let textView = textView else { return }
                guard self.linkPressGeneration == thisGeneration else { return }
                self.suppressNextLinkTap = true
                self.suppressLinkTapToken += 1
                let myToken = self.suppressLinkTapToken
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    guard let self = self, self.suppressLinkTapToken == myToken else { return }
                    self.suppressNextLinkTap = false
                }
                self.presentLinkActionSheet(urlString: urlString, sourceView: textView, sourceRect: LinkHighlighting.boundingRect(for: range, in: textView))
            }

        case .changed:
            if let info = LinkHighlighting.linkInfo(at: point, in: textView) {
                showLinkHighlight(range: info.range, in: textView)
            } else {
                hideLinkHighlight()
                linkPressGeneration += 1
            }

        case .ended, .cancelled, .failed:
            linkPressGeneration += 1
            hideLinkHighlight()

        default:
            break
        }
    }

    @objc private func handleMessageTextTap(_ sender: UITapGestureRecognizer) {
        if suppressNextLinkTap {
            suppressNextLinkTap = false
            return
        }

        guard let textView = sender.view as? UITextView else { return }
        let point = sender.location(in: textView)
        guard let info = LinkHighlighting.linkInfo(at: point, in: textView) else { return }

        LinkOpener.open(urlString: info.urlString)
    }
}

// MARK: - Transfers

extension EditorStarMessages {
    // Fix: a transfer reports back long after it was started, and the index path it was
    // started from is only good at that one moment - a message arriving or being deleted
    // shifts it, and leaving and re-entering the chat rebuilds the table from scratch. So
    // the row is looked up again, by the file the transfer is for, every time it reports.
    func indexPathForMessage(withFileNamed name: String) -> IndexPath? {
        guard !name.isEmpty else {
            return nil
        }
        let fileKeys = ["image_id", "video_id", "file_id", "audio_id", "thumb_id", "gif_id"]
        guard let index = dataMessages.lastIndex(where: { message in
            return fileKeys.contains(where: { (message[$0] as? String ?? "") == name })
        }) else {
            return nil
        }
        guard let section = dataDates.firstIndex(of: dataMessages[index]["chat_date"] as? String ?? "") else {
            return nil
        }
        let messageId = dataMessages[index]["message_id"] as? String
        guard let row = dataMessages
            .filter({ $0["chat_date"] as? String ?? "" == dataDates[section] })
            .firstIndex(where: { $0["message_id"] as? String == messageId }) else {
            return nil
        }
        return IndexPath(row: row, section: section)
    }

    // Keeps the "3,4 MB / 12 MB" caption beside a progress ring current. Does nothing when
    // the message is not on screen - cellForRow fills the caption in when it comes back.
    func updateTransferSize(forFileNamed name: String) {
        guard let indexPath = indexPathForMessage(withFileNamed: name),
              let cell = tableChatView.cellForRow(at: indexPath) else {
            return
        }
        ChatTransferRing.updateSizeText(forFileNamed: name, in: cell)
    }

    // Reloads the row a transfer belongs to, if it is still on screen at all. Safe to call
    // from a download that outlived the screen which started it.
    func reloadMessageRow(withFileNamed name: String) {
        guard let indexPath = indexPathForMessage(withFileNamed: name),
              indexPath.section < tableChatView.numberOfSections,
              indexPath.row < tableChatView.numberOfRows(inSection: indexPath.section) else {
            return
        }
        tableChatView.reloadRows(at: [indexPath], with: .none)
    }
}
