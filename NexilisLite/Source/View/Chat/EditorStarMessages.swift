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

public class EditorStarMessages: UIViewController, UITableViewDataSource, UITableViewDelegate, UIContextMenuInteractionDelegate, QLPreviewControllerDataSource, UITextViewDelegate {
    @IBOutlet var tableChatView: UITableView!
    var dataMessages: [[String: Any?]] = []
    var dataDates: [String] = []
    var previewItem = NSURL()
    var fromNotification = false
    var timerCheckLink: Timer?
    var showMenuContext = false
    var touchedSubview = UIView()
    var lastTouchPoint: CGPoint = .zero
    
    var downloadList: [String: IndexPath] = [:]
    var transitioningDelegateRef: ZoomTransitioningDelegate?
    
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
        topAnchor = dateView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20.0)
        NSLayoutConstraint.activate([
            topAnchor,
            dateView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20.0),
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
        labelDate.font = UIFont.systemFont(ofSize: 12 + offset(), weight: .medium)
        labelDate.text = dataDates[section]
        return containerView
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 80
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        dataDates.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = dataMessages.filter({ $0["chat_date"] as! String == dataDates[section] }).count
        return count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let idMe = User.getMyPin() as String?
        let dataMessages = dataMessages.filter({$0["chat_date"] as! String == dataDates[indexPath.section]})
        
        let cellMessage = UITableViewCell()
        cellMessage.backgroundColor = .clear
        cellMessage.selectionStyle = .none
        
        let profileMessage = UIImageView()
        profileMessage.frame.size = CGSize(width: 35, height: 35)
        cellMessage.contentView.addSubview(profileMessage)
        profileMessage.translatesAutoresizingMaskIntoConstraints = false
        
        let containerMessage = UIView()
        let interaction = UIContextMenuInteraction(delegate: self)
        containerMessage.addInteraction(interaction)
        containerMessage.isUserInteractionEnabled = true
        cellMessage.contentView.addSubview(containerMessage)
        containerMessage.translatesAutoresizingMaskIntoConstraints = false
        
        let timeMessage = UILabel()
        cellMessage.contentView.addSubview(timeMessage)
        timeMessage.translatesAutoresizingMaskIntoConstraints = false
        timeMessage.bottomAnchor.constraint(equalTo: cellMessage.contentView.bottomAnchor, constant: -5 - 20).isActive = true
        
        let messageText = UITextView()
        messageText.isEditable = false
        messageText.isSelectable = true
        messageText.dataDetectorTypes = []
        messageText.backgroundColor = .clear
        messageText.isScrollEnabled = false
        messageText.textContainerInset = UIEdgeInsets.zero
        messageText.contentInset = UIEdgeInsets.zero
        messageText.textDragInteraction?.isEnabled = false
        containerMessage.addSubview(messageText)
        messageText.translatesAutoresizingMaskIntoConstraints = false
        let topMarginText = messageText.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 32)
        
        let dataProfile = getDataProfile(f_pin: dataMessages[indexPath.row]["f_pin"] as! String)
        
        let statusMessage = UIImageView()
        
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
            containerMessage.leadingAnchor.constraint(greaterThanOrEqualTo: cellMessage.contentView.leadingAnchor, constant: 80).isActive = true
            containerMessage.bottomAnchor.constraint(equalTo: cellMessage.contentView.bottomAnchor, constant: -5 - 20).isActive = true
            containerMessage.trailingAnchor.constraint(equalTo: profileMessage.leadingAnchor, constant: -5).isActive = true
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            if (dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"]as? String == "") {
                containerMessage.backgroundColor = .clear
            } else {
                containerMessage.backgroundColor = .mainColor
            }
            containerMessage.layer.cornerRadius = 10.0
            containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
            containerMessage.clipsToBounds = true
            
            timeMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            
            cellMessage.contentView.addSubview(statusMessage)
            statusMessage.translatesAutoresizingMaskIntoConstraints = false
            statusMessage.bottomAnchor.constraint(equalTo: timeMessage.topAnchor).isActive = true
            statusMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            statusMessage.widthAnchor.constraint(equalToConstant: 15).isActive = true
            statusMessage.heightAnchor.constraint(equalToConstant: 15).isActive = true
            if (dataMessages[indexPath.row]["status"]! as! String == "1" || dataMessages[indexPath.row]["status"]! as! String == "2" ) {
                statusMessage.image = UIImage(named: "checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
            } else if (dataMessages[indexPath.row]["status"]! as! String == "3") {
                statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
            } else {
                statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
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
                nameSender.textColor = .mainColor
            } else {
                containerMessage.backgroundColor = .mainColor
                nameSender.textColor = .white
            }
            
        } else {
            profileMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 5).isActive = true
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
            if dataMessages[indexPath.row]["f_pin"] as! String == "-999" {
                if !Utils.getIconDock().isEmpty {
                    let dataImage = try? Data(contentsOf: URL(string: Utils.getUrlDock()!)!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                    if dataImage != nil {
                        profileMessage.image = UIImage(data: dataImage!)
                    }
                } else {
                    profileMessage.image = UIImage(named: "pb_button", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                }
                profileMessage.contentMode = .scaleAspectFit
            }
            if (pictureImage != "" && pictureImage != nil) {
                profileMessage.setImage(name: pictureImage!)
                profileMessage.contentMode = .scaleAspectFill
            }
            
            containerMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 5).isActive = true
            containerMessage.leadingAnchor.constraint(equalTo: profileMessage.trailingAnchor, constant: 5).isActive = true
            containerMessage.bottomAnchor.constraint(equalTo: cellMessage.contentView.bottomAnchor, constant: -5 - 20).isActive = true
            containerMessage.trailingAnchor.constraint(lessThanOrEqualTo: cellMessage.contentView.trailingAnchor, constant: -80).isActive = true
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            if (dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"]as? String == "") {
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
            nameSender.text = dataProfile["name"]
            nameSender.textAlignment = .left
            nameSender.textColor = .mainColor
        }
        
        if (dataMessages[indexPath.row]["is_stared"] as? String == "1") {
            let imageStared = UIImageView()
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
        topMarginText.isActive = true
        if dataMessages[indexPath.row]["attachment_flag"] as! String == "27" || dataMessages[indexPath.row]["attachment_flag"] as! String == "26" {
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
            }
        } else {
            messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
        }
        messageText.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: -15).isActive = true
        messageText.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
        
        var textChat = (dataMessages[indexPath.row]["message_text"])! as? String
        if (dataMessages[indexPath.row]["lock"] != nil && (dataMessages[indexPath.row]["lock"])! as? String == "1") {
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                textChat = "🚫 _"+"You were deleted this message".localized()+"_"
            } else {
                textChat = "🚫 _"+"This message was deleted".localized()+"_"
            }
        }
        let imageSticker = UIImageView()
        if let attachmentFlag = dataMessages[indexPath.row]["attachment_flag"], let attachmentFlag = attachmentFlag as? String {
            if attachmentFlag == "27" || attachmentFlag == "26", let data = textChat { // live streaming
                if let json = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                    Database.shared.database?.inTransaction({ fmdb, rollback in
                        let title = json["title"] as! String
                        let description = json["description"] as! String
                        let start = json["time"] as! Int64
                        let by = json["by"] as! String
                        var type = "*Live Streaming*"
                        if attachmentFlag == "26" {
                            type = "*Seminar*"
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
            } else if attachmentFlag == "11" {
                messageText.text = ""
                topMarginText.constant = topMarginText.constant + 100
                containerMessage.addSubview(imageSticker)
                imageSticker.translatesAutoresizingMaskIntoConstraints = false
                imageSticker.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 27.0).isActive = true
                imageSticker.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor).isActive = true
                imageSticker.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                imageSticker.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor).isActive = true
                imageSticker.widthAnchor.constraint(equalToConstant: 80).isActive = true
                var imageStickerBundle = UIImage(named: (textChat!.components(separatedBy: "/")[1]), in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                if imageStickerBundle == nil {
                    imageStickerBundle = UIImage(named: (textChat!.components(separatedBy: "/")[1]), in: Bundle.resourcesMediaBundle(for: Nexilis.self), with: nil)
                }
                imageSticker.image = imageStickerBundle //resourcesMediaBundle
                imageSticker.contentMode = .scaleAspectFit
            }
            else {
                modifyText()
            }
        } else {
            modifyText()
        }
        messageText.font = UIFont.systemFont(ofSize: 12 + offset())
        
        func modifyText() {
            if !textChat!.isEmpty {
                if textChat!.contains("■"){
                    textChat = textChat!.components(separatedBy: "■")[0]
                    textChat = textChat!.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                let finalAtribute = textChat!.richText()
                textChat = finalAtribute.string
                let urlPattern = "(https?://|www\\.)\\S+"
                if let regex = try? NSRegularExpression(pattern: urlPattern, options: []) {
                    let matches = regex.matches(in: textChat!, options: [], range: NSRange(textChat!.startIndex..., in: textChat!))
                    
                    for match in matches {
                        if let range = Range(match.range, in: textChat!) {
                            let linkText = String(textChat![range])
                            let nsRange = NSRange(range, in: textChat!)
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
        
        if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
            messageText.textColor = .white
        } else {
            messageText.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        }
        
        let stringDate = (dataMessages[indexPath.row]["server_date"] as! String)
        let date = Date(milliseconds: Int64(stringDate)!)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
        timeMessage.text = formatter.string(from: date as Date)
        timeMessage.font = UIFont.systemFont(ofSize: 10 + offset(), weight: .medium)
        timeMessage.textColor = .lightGray
        
        let thumbChat = dataMessages[indexPath.row]["thumb_id"] as! String
        let imageChat = dataMessages[indexPath.row]["image_id"] as! String
        let videoChat = dataMessages[indexPath.row]["video_id"] as! String
        let fileChat = dataMessages[indexPath.row]["file_id"] as! String
        
        let imageThumb = UIImageView()
        let containerViewFile = UIView()
        
        if (!thumbChat.isEmpty) {
            topMarginText.constant = topMarginText.constant + 205
            
            containerMessage.addSubview(imageThumb)
            imageThumb.translatesAutoresizingMaskIntoConstraints = false
            imageThumb.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 32).isActive = true
            imageThumb.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            imageThumb.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
            imageThumb.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
            imageThumb.widthAnchor.constraint(equalToConstant: self.view.frame.size.width * 0.6).isActive = true
            imageThumb.layer.cornerRadius = 5.0
            imageThumb.clipsToBounds = true
            imageThumb.contentMode = .scaleAspectFill
            
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(thumbChat)
                let image    = UIImage(contentsOfFile: thumbURL.path)
                imageThumb.image = image
                
                let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(videoChat)
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(imageChat)
                if !FileManager.default.fileExists(atPath: imageURL.path) && !FileManager.default.fileExists(atPath: videoURL.path) && !FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) && !FileEncryption.shared.isSecureExists(filename: videoURL.lastPathComponent){
                    let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
                    let blurEffectView = UIVisualEffectView(effect: blurEffect)
                    blurEffectView.frame = CGRect(x: 0, y: 0, width: imageThumb.frame.size.width, height: imageThumb.frame.size.height)
                    blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    let imageDownload = UIImageView(image: UIImage(systemName: "arrow.down.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .default)))
                    imageThumb.addSubview(blurEffectView)
                    imageThumb.addSubview(imageDownload)
                    imageDownload.tintColor = .black.withAlphaComponent(0.3)
                    imageDownload.translatesAutoresizingMaskIntoConstraints = false
                    imageDownload.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                    imageDownload.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
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
                let circlePath = UIBezierPath(arcCenter: CGPoint(x: 10, y: 20), radius: 15, startAngle: -(.pi / 2), endAngle: .pi * 2, clockwise: true)
                let trackShape = CAShapeLayer()
                trackShape.path = circlePath.cgPath
                trackShape.fillColor = UIColor.black.withAlphaComponent(0.3).cgColor
                trackShape.lineWidth = 3
                trackShape.strokeColor = UIColor.mainColor.withAlphaComponent(0.3).cgColor
                container.backgroundColor = .clear
                container.layer.addSublayer(trackShape)
                let shapeLoading = CAShapeLayer()
                shapeLoading.path = circlePath.cgPath
                shapeLoading.fillColor = UIColor.clear.cgColor
                shapeLoading.lineWidth = 3
                shapeLoading.strokeEnd = 0
                shapeLoading.strokeColor = UIColor.mainColor.cgColor
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
            
            let objectTap = ObjectGesture(target: self, action: #selector(contentMessageTapped(_:)))
            let sfs = (dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String) ?? ""
            imageThumb.isUserInteractionEnabled = true
            imageThumb.addGestureRecognizer(objectTap)
            objectTap.image_id = imageChat
            objectTap.video_id = videoChat
            objectTap.specFile = sfs
            objectTap.imageView = imageThumb
            objectTap.indexPath = indexPath
        }
        
        if (!fileChat.isEmpty) {
            topMarginText.constant = topMarginText.constant + 55
            
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            let arrExtFile = (textChat?.components(separatedBy: "|")[0])?.split(separator: ".")
            let finalExtFile = arrExtFile![arrExtFile!.count - 1]
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
                    if var dataFile = try? FileEncryption.shared.readSecure(filename: fileChat) {
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
                    } else {
                        messageText.text = ""
                    }
                }
            }
            
            containerMessage.addSubview(containerViewFile)
            containerViewFile.translatesAutoresizingMaskIntoConstraints = false
            containerViewFile.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 32).isActive = true
            containerViewFile.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            containerViewFile.bottomAnchor.constraint(equalTo:messageText.topAnchor, constant: -5).isActive = true
            containerViewFile.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
            containerViewFile.heightAnchor.constraint(equalToConstant: 50).isActive = true
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
            nameFile.text = textChat?.components(separatedBy: "|")[0]
            
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
                trackShape.strokeColor = UIColor.mainColor.withAlphaComponent(0.3).cgColor
                containerLoading.layer.addSublayer(trackShape)
                let shapeLoading = CAShapeLayer()
                shapeLoading.path = circlePath.cgPath
                shapeLoading.fillColor = UIColor.clear.cgColor
                shapeLoading.lineWidth = 3
                shapeLoading.strokeEnd = 0
                shapeLoading.strokeColor = UIColor.mainColor.cgColor
                containerLoading.layer.addSublayer(shapeLoading)
                let imageupload = UIImageView(image: UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                imageupload.tintColor = .white
                containerLoading.addSubview(imageupload)
                imageupload.translatesAutoresizingMaskIntoConstraints = false
                imageupload.centerYAnchor.constraint(equalTo: containerLoading.centerYAnchor).isActive = true
                imageupload.centerXAnchor.constraint(equalTo: containerLoading.centerXAnchor).isActive = true
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
        if thumbChat.isEmpty && fileChat.isEmpty && !textChat!.isEmpty {
            var text = ""
            let listTextSplitBreak = textChat!.components(separatedBy: "\n")
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
                            if !imageUrl!.starts(with: "https://") {
                                imagePreview.loadImageAsync(with: "https://www.google.be" + imageUrl!)
                            } else {
                                imagePreview.loadImageAsync(with: imageUrl)
                            }
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
                        titlePreview.topAnchor.constraint(equalTo: containerLinkMessage.topAnchor, constant: 25.0).isActive = true
                        titlePreview.trailingAnchor.constraint(equalTo: containerLinkMessage.trailingAnchor, constant: -80.0).isActive = true
                        titlePreview.text = title
                        titlePreview.font = UIFont.systemFont(ofSize: 14.0 + offset(), weight: .bold)
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
                        descPreview.trailingAnchor.constraint(equalTo: containerLinkMessage.trailingAnchor, constant: -80.0).isActive = true
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
                        linkPreview.trailingAnchor.constraint(equalTo: containerLinkMessage.trailingAnchor, constant: -80.0).isActive = true
                        linkPreview.text = link
                        linkPreview.font = UIFont.systemFont(ofSize: 10.0 + offset())
                        linkPreview.textColor = .gray
                        linkPreview.numberOfLines = 1
                        
                        let objectTap = ObjectGesture(target: self, action: #selector(tapMessageText(_:)))
                        objectTap.message_id = text
                        containerLinkMessage.addGestureRecognizer(objectTap)
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
                        let imageUrl = result.image
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
        
        let imageAckView = UIImageView()
        if dataMessages[indexPath.row]["read_receipts"] as? String == "8" {
            var imageAck = UIImage(named: "ack_icon_gray", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            if dataMessages[indexPath.row]["status"] as? String == "8" {
                imageAck = UIImage(named: "ack_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            }
            imageAckView.image = imageAck
            cellMessage.contentView.addSubview(imageAckView)
            imageAckView.translatesAutoresizingMaskIntoConstraints = false
            imageAckView.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageAckView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            imageAckView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                imageAckView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 30).isActive = true
            } else {
                imageAckView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -30).isActive = true
                let tap = ObjectGesture(target: self, action: #selector(tapAck(_:)))
                tap.indexPath = indexPath
                imageAckView.addGestureRecognizer(tap)
                imageAckView.isUserInteractionEnabled = true
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
                } else {
                    imageSpecFileView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 30).isActive = true
                }
            } else {
                if imageAckView.isDescendant(of: cellMessage.contentView) {
                    imageSpecFileView.trailingAnchor.constraint(equalTo: imageAckView.leadingAnchor, constant: -5).isActive = true
                } else {
                    imageSpecFileView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -30).isActive = true
                }
            }
        }
        
        return cellMessage
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
        
    @objc func tapMessageText(_ sender: ObjectGesture) {
        var stringURl = sender.message_id
        if stringURl.lowercased().starts(with: "www.") {
            stringURl = "https://" + stringURl.replacingOccurrences(of: "www.", with: "")
        }
        if Nexilis.checkingAccess(key: "secure_browser") {
            APIS.openUrl(url: stringURl)
        } else {
            guard let url = URL(string: stringURl) else { return }
            UIApplication.shared.open(url)
        }
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
                    var activityViewController = UIActivityViewController(activityItems: [image ?? UIImage()], applicationActivities: nil)
                    if type == 1 {
                        activityViewController = UIActivityViewController(activityItems: [url ?? URL(string: "")!], applicationActivities: nil)
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
                            self.tableChatView.reloadData()
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
                    trackShape.strokeColor = UIColor.mainColor.withAlphaComponent(0.3).cgColor
                    container.backgroundColor = .clear
                    container.layer.addSublayer(trackShape)
                    let shapeLoading = CAShapeLayer()
                    shapeLoading.path = circlePath.cgPath
                    shapeLoading.fillColor = UIColor.clear.cgColor
                    shapeLoading.lineWidth = 10
                    shapeLoading.strokeEnd = 0
                    shapeLoading.strokeColor = UIColor.mainColor.cgColor
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
                        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(sender.labelFile.text ?? "")
                        do {
                            try fileManager.copyItem(at: urlFile, to: tempURL)
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
                                    containerMessage.backgroundColor = .mainColor
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
    
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        if showMenuContext {
            showMenuContext = false
            interaction.view!.removeInteraction(interaction)
        }
    }
    
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let indexPath = self.tableChatView.indexPathForRow(at: interaction.view!.convert(location, to: self.tableChatView))
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath!.section]})
        let star = UIAction(title: "Unstar".localized(), image: UIImage(systemName: "star.slash.fill"), handler: {(_) in
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
        let forward = UIAction(title: "Forward".localized(), image: UIImage(systemName: "arrowshape.turn.up.right.fill"), handler: {(_) in
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
        let copy = UIAction(title: "Copy".localized(), image: UIImage(systemName: "doc.on.doc.fill"), handler: {(_) in
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
        if (Nexilis.checkingAccess(key: "secure_folder_forward") || (dataMessages[indexPath!.row][TypeDataMessage.spec_file] as? String ?? "").contains("forward")) && self.dataMessages[indexPath!.row]["f_pin"] as! String != "-999" {
            children.insert(forward, at: 1)
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
        let message = dataMessages[indexPath.row]
        if let attachmentFlag = message["attachment_flag"], let attachmentFlag = attachmentFlag as? String {
            if attachmentFlag == "27" {
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
