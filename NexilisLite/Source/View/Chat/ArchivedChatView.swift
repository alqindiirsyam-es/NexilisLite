//
//  ArchivedChatView.swift
//  Pods
//
//  Created by Qindi on 02/06/25.
//

import Foundation
import UIKit

public class ArchivedChatView: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let contactChatNav = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactChatNav") as! UINavigationController
    private let tableView = UITableView(frame: .zero, style: .plain)
    public var archivedChats: [Chat] = []
    var archivedChatGroupMaps: [String: [Chat]] = [:]
    
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
    }
    
    public override func viewDidLoad() {
        Utils.addBackground(view: contactChatNav.view)
        reloadArchiveChat()
        self.title = "Archived".localized()
        self.navigationController?.navigationBar.topItem?.title = "".localized()
        self.navigationController?.navigationBar.setNeedsLayout()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellChatArchived")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        setupTableView()
        
    }
    
    private func reloadArchiveChat() {
        self.archivedChatGroupMaps.removeAll()
        let previousChat = self.archivedChats
        let allChats = Chat.getData(isArchived: true)
        var tempChats: [Chat] = []

        for singleChat in allChats {
            guard !singleChat.groupId.isEmpty else {
                tempChats.append(singleChat)
                continue
            }
            
            let chatParentInPreviousChats = previousChat.first { $0.isParent && $0.groupId == singleChat.groupId }
            
            if var existingGroup = self.archivedChatGroupMaps[singleChat.groupId] {
                existingGroup.insert(singleChat, at: 0)
                self.archivedChatGroupMaps[singleChat.groupId] = existingGroup
                
                if let parentChatIndex = tempChats.firstIndex(where: { $0.groupId == singleChat.groupId && $0.isParent }) {
                    if let counterParent = Int(tempChats[parentChatIndex].counter), let counterSingle = Int(singleChat.counter) {
                        tempChats[parentChatIndex].counter = "\(counterParent + counterSingle)"
                    }
                }
                
                if let parentExist = chatParentInPreviousChats, parentExist.isSelected,
                   let indexParent = tempChats.firstIndex(where: { $0.isParent && $0.groupId == singleChat.groupId }) {
                    tempChats.insert(singleChat, at: min(indexParent + existingGroup.count, tempChats.count))
                }
            } else {
                self.archivedChatGroupMaps[singleChat.groupId] = [singleChat]
                let parentChat = Chat(profile: singleChat.profile, groupName: singleChat.groupName, counter: singleChat.counter, groupId: singleChat.groupId)
                parentChat.isParent = true
                
                if let parentExist = chatParentInPreviousChats, parentExist.isSelected {
                    parentChat.isSelected = true
                    tempChats.append(parentChat)
                    tempChats.append(singleChat)
                } else {
                    tempChats.append(parentChat)
                }
            }
        }

        self.archivedChats = tempChats
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return archivedChats.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let fontSize = Int(SecureUserDefaults.shared.value(forKey: "font_size") ?? "0")
        var finalHeight = 75.0
        if fontSize == 4 {
            finalHeight += 10
        } else if fontSize == 6 {
            finalHeight += 20
        }
        return finalHeight
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let data = archivedChats[indexPath.row]
        if data.isParent {
            expandCollapseChats(tableView: tableView, indexPath: indexPath)
            return
        }
        if data.pin == "-997" {
            let smartChatVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "chatGptVC") as! ChatGPTBotView
            smartChatVC.hidesBottomBarWhenPushed = true
            smartChatVC.fromNotification = false
            navigationController?.show(smartChatVC, sender: nil)
        } else if data.messageScope == MessageScope.WHISPER || data.messageScope == MessageScope.CALL || data.messageScope == MessageScope.MISSED_CALL {
            if data.pin.isEmpty {
                return
            }
            let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
            editorPersonalVC.hidesBottomBarWhenPushed = true
            editorPersonalVC.unique_l_pin = data.pin
            navigationController?.show(editorPersonalVC, sender: nil)
        } else {
            if data.pin.isEmpty {
                return
            }
            let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
            editorGroupVC.hidesBottomBarWhenPushed = true
            editorGroupVC.unique_l_pin = data.pin
            navigationController?.show(editorGroupVC, sender: nil)
        }
    }
    
    func expandCollapseChats(tableView: UITableView, indexPath: IndexPath) {
        let data = archivedChats[indexPath.row]
        data.isSelected = !data.isSelected
        if data.isSelected {
            if let dataSubChats = self.archivedChatGroupMaps[data.groupId] {
                for dataSubChat in dataSubChats {
                    if var indexParent = archivedChats.firstIndex(where: { $0.isParent && $0.groupId == data.groupId }) {
                        archivedChats.insert(dataSubChat, at: indexParent + 1)
                        indexParent+=1
                    }
                    
                }
            }
        } else {
            archivedChats.removeAll(where: { $0.isParent == false && $0.groupId == data.groupId })
        }
        tableView.reloadData()
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellChatArchived", for: indexPath)
        let content = cell.contentView
        if content.subviews.count > 0 {
            content.subviews.forEach { $0.removeFromSuperview() }
        }
        let data = archivedChats[indexPath.row]
        let imageView = UIImageView()
        content.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 55.0),
            imageView.heightAnchor.constraint(equalToConstant: 55.0)
        ])
        var leadingAnchor = imageView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 10.0)
        if data.pin == "-997" {
            imageView.frame = CGRect(x: 0, y: 0, width: 55.0, height: 55.0)
            imageView.circle()
            if let urlGif = Bundle.resourceBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif") {
                imageView.sd_setImage(with: urlGif) { (image, error, cacheType, imageURL) in
                    if error == nil {
                        imageView.animationImages = image?.images
                        imageView.animationDuration = image?.duration ?? 0.0
                        imageView.animationRepeatCount = 0
                        imageView.startAnimating()
                    }
                }
            } else if let urlGif = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif") {
                imageView.sd_setImage(with: urlGif) { (image, error, cacheType, imageURL) in
                    if error == nil {
                        imageView.animationImages = image?.images
                        imageView.animationDuration = image?.duration ?? 0.0
                        imageView.animationRepeatCount = 0
                        imageView.startAnimating()
                    }
                }
            }
        } else {
            if !Utils.getIconDock().isEmpty && data.official == "1" {
                let urlString = Utils.getUrlDock()!
                if let cachedImage = ImageCache.shared.image(forKey: urlString) {
                    let imageData = cachedImage
                    imageView.image = imageData
                } else {
                    DispatchQueue.global().async{
                        Utils.fetchDataWithCookiesAndUserAgent(from: URL(string: urlString)!) { data, response, error in
                            guard let data = data, error == nil else { return }
                            DispatchQueue.main.async() {
                                if UIImage(data: data) != nil {
                                    let imageData = UIImage(data: data)!
                                    imageView.image = imageData
                                    ImageCache.shared.save(image: imageData, forKey: urlString)
                                }
                            }
                        }
                    }
                }
            } else {
                if data.messageScope == MessageScope.WHISPER || data.messageScope == MessageScope.CALL || data.messageScope == MessageScope.MISSED_CALL || data.isParent || data.pin == "-999" {
                    getImage(name: data.profile, placeholderImage: UIImage(named: data.pin == "-999" ? "pb_button" : (data.messageScope == MessageScope.WHISPER || data.messageScope == MessageScope.CALL || data.messageScope == MessageScope.MISSED_CALL) ? "Profile---Purple" : "Conversation---Black", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                        imageView.image = image
                    })
                } else {
                    leadingAnchor = imageView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 40.0)
                    let image = UIImage(named: "Conversation---Black", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                    imageView.image = image
                }
            }
        }
        leadingAnchor.isActive = true
        
        let titleView = UILabel()
        content.addSubview(titleView)
        titleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10.0),
            titleView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -40.0),
        ])
        titleView.font = UIFont.systemFont(ofSize: 14 + String.offset(), weight: .medium)
        
        let timeView = UILabel()
        let viewCounter = UIView()
        
        if data.counter != "0" {
            timeView.textColor = .systemRed
            content.addSubview(viewCounter)
            viewCounter.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                viewCounter.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
                viewCounter.heightAnchor.constraint(equalToConstant: 20)
            ])
            viewCounter.backgroundColor = .systemRed
            viewCounter.layer.cornerRadius = 10
            viewCounter.clipsToBounds = true
            viewCounter.layer.borderWidth = 0.5
            viewCounter.layer.borderColor = UIColor.secondaryColor.cgColor

            let labelCounter = UILabel()
            viewCounter.addSubview(labelCounter)
            labelCounter.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                labelCounter.centerYAnchor.constraint(equalTo: viewCounter.centerYAnchor),
                labelCounter.leadingAnchor.constraint(equalTo: viewCounter.leadingAnchor, constant: 2),
                labelCounter.trailingAnchor.constraint(equalTo: viewCounter.trailingAnchor, constant: -2),
            ])
            labelCounter.font = UIFont.systemFont(ofSize: 11 + String.offset())
            if Int(data.counter) ?? 0 > 99 {
                labelCounter.text = "99+"
            } else {
                labelCounter.text = data.counter
            }
            labelCounter.textColor = .secondaryColor
            labelCounter.textAlignment = .center
        }
        
        if !data.isParent {
            titleView.topAnchor.constraint(equalTo: content.topAnchor, constant: 10.0).isActive = true
            titleView.text = data.name
            
            content.addSubview(timeView)
            timeView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                timeView.topAnchor.constraint(equalTo: content.topAnchor, constant: 10.0),
                timeView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20.0),
            ])
            timeView.textColor = .gray
            timeView.font = UIFont.systemFont(ofSize: 14 + String.offset())
            
            let date = Date(milliseconds: Int64(data.serverDate) ?? 0)
            let calendar = Calendar.current
            
            if (calendar.isDateInToday(date)) {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                timeView.text = formatter.string(from: date as Date)
            } else {
                let startOfNow = calendar.startOfDay(for: Date())
                let startOfTimeStamp = calendar.startOfDay(for: date)
                let components = calendar.dateComponents([.day], from: startOfNow, to: startOfTimeStamp)
                let day = -(components.day!)
                if day == 1 {
                    timeView.text = "Yesterday".localized()
                } else {
                    if day < 7 {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "EEEE"
                        let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
                        if lang == "id" {
                            formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                        }
                        timeView.text = formatter.string(from: date)
                    } else {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "M/dd/yy"
                        formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                        let stringFormat = formatter.string(from: date as Date)
                        timeView.text = stringFormat
                    }
                }
            }
            
            let messageView = UILabel()
            content.addSubview(messageView)
            messageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                messageView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10.0),
                messageView.topAnchor.constraint(equalTo: titleView.bottomAnchor),
                messageView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -40.0),
            ])
            messageView.textColor = .gray
            if data.messageText.contains("■") {
                data.messageText = data.messageText.components(separatedBy: "■")[0]
                data.messageText = data.messageText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            let text = Utils.previewMessageText(chat: data)
            let idMe = User.getMyPin() as String?
            if let attributeText = text as? NSMutableAttributedString {
                let stringMessage = NSMutableAttributedString(string: "")
                if data.fpin == idMe {
                    if data.lock == "1" {
                        if data.messageScope == "4" {
                            stringMessage.append(NSAttributedString(string: "You".localized() + ": ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12 + String.offset(), weight: .medium)]))
                        }
                        stringMessage.append(("🚫 _"+"You were deleted this message".localized()+"_").richText())
                    } else {
                        let imageStatus = NSTextAttachment()
                        if data.messageScope != MessageScope.CALL && data.messageScope != MessageScope.MISSED_CALL {
                            let status = getRealStatus(messageId: data.messageId)
                            if status == "0" {
                                imageStatus.image = UIImage(systemName: "xmark.circle")!.withTintColor(UIColor.red, renderingMode: .alwaysOriginal)
                            } else if status == "1" {
                                imageStatus.image = UIImage(systemName: "clock.arrow.circlepath")!.withTintColor(UIColor.lightGray, renderingMode: .alwaysOriginal)
                            } else if status == "2" {
                                imageStatus.image = UIImage(named: "checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
                            } else if (status == "3") {
                                imageStatus.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
                            } else if (status == "8") {
                                imageStatus.image = UIImage(named: "message_status_ack", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
                            } else {
                                imageStatus.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
                            }
                            imageStatus.bounds = CGRect(x: 0, y: -5, width: 15, height: 15)
                            let imageStatusString = NSAttributedString(attachment: imageStatus)
                            stringMessage.append(imageStatusString)
                            stringMessage.append(NSAttributedString(string: " "))
                        }
                        if data.messageScope == "4" {
                            stringMessage.append(NSAttributedString(string: "You".localized() + ": ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12 + String.offset(), weight: .medium)]))
                        }
                        stringMessage.append(attributeText)
                    }
                } else {
                    if data.messageScope == "4" {
                        var fullname = User.getData(pin: data.fpin, lPin: data.pin)!.fullName
                        let components = fullname.split(separator: " ")
                        if components.count >= 2 {
                            fullname = components.prefix(2).joined(separator: " ")
                        }
                        stringMessage.append(NSAttributedString(string: fullname + ": ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12 + String.offset(), weight: .medium)]))
                    }
                    if data.lock == "1" {
                        stringMessage.append(("🚫 _"+"This message was deleted".localized()+"_").richText())
                    } else {
                        stringMessage.append(attributeText)
                    }
                }
                messageView.attributedText = stringMessage
            }
            messageView.numberOfLines = 2
            
            if data.counter != "0" {
                viewCounter.topAnchor.constraint(equalTo: timeView.bottomAnchor, constant: 5.0).isActive = true
                viewCounter.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20).isActive = true
            }
        } else {
            titleView.centerYAnchor.constraint(equalTo: content.centerYAnchor).isActive = true
            titleView.text = data.groupName
            
            let iconName = (data.isSelected) ? "chevron.up.circle" : "chevron.down.circle"
            let imageView = UIImageView(image: UIImage(systemName: iconName))
            imageView.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
            content.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
                imageView.centerYAnchor.constraint(equalTo: content.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 20),
                imageView.heightAnchor.constraint(equalToConstant: 20)
            ])
            
            if data.counter != "0" {
                viewCounter.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -5).isActive = true
                viewCounter.centerYAnchor.constraint(equalTo: content.centerYAnchor).isActive = true
            }
        }
        cell.backgroundColor = .clear
        cell.separatorInset = UIEdgeInsets(top: 0, left: 60.0, bottom: 0, right: 0)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let data = archivedChats[indexPath.row]
        if !data.isParent {
            let archiveAction = UIContextualAction(style: .normal, title: nil) { (_, _, completionHandler) in
                DispatchQueue.global().async {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                                "archived" : 0
                            ], _where: "l_pin = '\(data.pin)'")
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                }
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                self.archivedChats.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .right)
                self.reloadArchiveChat()
                tableView.reloadData()
                if self.archivedChats.count == 0 {
                    self.navigationController?.popViewController(animated: true)
                }
                completionHandler(true)
            }
            archiveAction.backgroundColor = .mainColor
            let archiveIcon = UIImage(systemName: "arrow.up.bin.fill")!.createCustomIconWithText(text: "Unarchive".localized())
            archiveAction.image = archiveIcon

            let configuration = UISwipeActionsConfiguration(actions: [archiveAction])
            return configuration
        }
        return nil
    }
    
    private func getRealStatus(messageId: String) -> String {
        var status = "1"
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursorStatus = Database.shared.getRecords(fmdb: fmdb, query: "SELECT status, f_pin FROM MESSAGE_STATUS WHERE message_id='\(messageId)'") {
                var listStatus: [Int] = []
                while cursorStatus.next() {
                    listStatus.append(Int(cursorStatus.string(forColumnIndex: 0)!)!)
                }
                cursorStatus.close()
                status = "\(listStatus.min() ?? 2)"
            }
        })
        return status
    }
    
    
}
