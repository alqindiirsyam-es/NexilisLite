//
//  ChatWALikeVC.swift
//  Pods
//
//  Created by Qindi on 11/04/25.
//

import Foundation
import UIKit
import AVFAudio
import QuickLook

public class ChatWALikeVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, QLPreviewControllerDataSource, UISearchBarDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchController = UISearchController(searchResultsController: nil)
    
    var chats: [Chat] = []
    var tempChats: [Chat] = []
    var chatGroupMaps: [String: [Chat]] = [:]
    var loadingData = true
    private let textChatEmpty = UILabel()
    
    let contAll = UIButton(type: .custom)
    let textAll = UILabel()
    let contUnread = UIButton(type: .custom)
    let textUnread = UILabel()
    let contGroups = UIButton(type: .custom)
    let textGroups = UILabel()
    
    private static var filterMain = 0
    
    var fillteredData: [Any] = []
    var fillteredMessages: [Chat] = []
    
    var isFiltering: Bool {
        return !searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && searchController.searchBar.text!.count > 1
    }
    
    var previewItem: NSURL?
    var audioPlayer: AVAudioPlayer?
    
    let UNREAD_TAG = 10
    let PHOTOS_TAG = 11
    let DOCUMENTS_TAG = 12
    let LINKS_TAG = 13
    let VIDEOS_TAG = 14
    let GIFS_TAG = 15
    let AUDIOS_TAG = 16
    
    var selectedTag = 0
    
    public override func viewDidLoad() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellChatWA")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.automaticallyAdjustsScrollIndicatorInsets = false
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        setupTableView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        navigationItem.title = "Chats".localized()
        navigationItem.hidesSearchBarWhenScrolling = true
        tabBarController?.navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.tintColor = .black
        navigationController?.navigationBar.overrideUserInterfaceStyle = .light
        self.setNeedsStatusBarAppearanceUpdate()
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black, NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)]
        let largeAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black, NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 34)]
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = attributes
        appearance.largeTitleTextAttributes = largeAttributes
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
        
//        let leftButton = UIButton(type: .system)
//        let imageLeft = UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold))
//        leftButton.setImage(imageLeft, for: .normal)
//        leftButton.tintColor = .black
//        leftButton.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
//        leftButton.layer.cornerRadius = 15
//        leftButton.clipsToBounds = true
//        leftButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
//        leftButton.addTarget(self, action: #selector(leftBarButtonTapped), for: .touchUpInside)
//        let leftBarButtonItem = UIBarButtonItem(customView: leftButton)
//        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        let rightButton = UIButton(type: .system)
        let imageRight = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold))
        rightButton.setImage(imageRight, for: .normal)
        rightButton.tintColor = .white
        rightButton.backgroundColor = .whatsappGreenColor
        rightButton.layer.cornerRadius = 15
        rightButton.clipsToBounds = true
        rightButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        rightButton.addTarget(self, action: #selector(rightBarButtonTapped), for: .touchUpInside)
        let rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        navigationItem.rightBarButtonItem = rightBarButtonItem
        
        searchController.searchResultsUpdater = self
        searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "Search".localized(), attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)])
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.delegate = self

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        DispatchQueue.main.async {
            self.navigationController?.navigationBar.sizeToFit()
        }
    }
    
    private func refresh() {
        getData { [self] in
            if tempChats.count == 0 {
                navigationItem.searchController = nil
                DispatchQueue.main.async {
                    self.navigationController?.navigationBar.sizeToFit()
                }
                if textChatEmpty.isDescendant(of: view) {
                    textChatEmpty.removeFromSuperview()
                }
                textChatEmpty.numberOfLines = 0
                let fullText = "To place chats, tap ⊕ at the top and select a contact.".localized()
                let attributedString = NSMutableAttributedString(string: fullText)
                attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 25), range: NSRange(location: 0, length: attributedString.length))
                if let plusRange = fullText.range(of: "⊕") {
                    let nsRange = NSRange(plusRange, in: fullText)
                    attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 40), range: nsRange)
                }
                textChatEmpty.attributedText = attributedString
                
                tableView.addSubview(textChatEmpty)
                textChatEmpty.anchor(left: tableView.leftAnchor, right: tableView.rightAnchor, paddingLeft: 20, paddingRight: 20, centerX: tableView.centerXAnchor)
                textChatEmpty.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: -60).isActive = true
            } else {
                if textChatEmpty.isDescendant(of: view) {
                    textChatEmpty.removeFromSuperview()
                }
            }
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        if Nexilis.floatingButton.isHidden {
            Nexilis.floatingButton.isHidden = false
        }
        refresh()
    }
    
    private func getData(completion: @escaping ()->()) {
        getChats {
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.loadingData = false
                completion()
            }
        }
    }
    
    func getChats(completion: @escaping ()->()) {
        DispatchQueue.global().async {
            self.chatGroupMaps.removeAll()
            let previousChat = self.chats
            let allChats = Chat.getData()
            var tempChats: [Chat] = []

            for singleChat in allChats {
                guard !singleChat.groupId.isEmpty else {
                    tempChats.append(singleChat)
                    continue
                }
                
                let chatParentInPreviousChats = previousChat.first { $0.isParent && $0.groupId == singleChat.groupId }
                
                if var existingGroup = self.chatGroupMaps[singleChat.groupId] {
                    existingGroup.insert(singleChat, at: 0)
                    self.chatGroupMaps[singleChat.groupId] = existingGroup
                    
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
                    self.chatGroupMaps[singleChat.groupId] = [singleChat]
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
            self.tempChats = tempChats
            if ChatWALikeVC.filterMain == 0 {
                self.chats = tempChats
            } else if ChatWALikeVC.filterMain == 1 {
                self.chats = tempChats.filter({ Int($0.counter) ?? 0 > 0 })
            } else {
                self.chats = tempChats.filter({ !$0.groupId.isEmpty })
            }
            completion()
        }
    }
    
    @objc func leftBarButtonTapped() {
        print("Left bar button tapped")
    }
    
    @objc func rightBarButtonTapped() {
        APIS.openChat()
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
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        
        if tempChats.count > 0 {
            header.addSubview(contAll)
            contAll.anchor(top: header.topAnchor, left: header.leftAnchor, bottom: header.bottomAnchor, paddingLeft: 20, height: 30)
            contAll.layer.cornerRadius = 15
            contAll.clipsToBounds = true
            contAll.tag = 0
            contAll.backgroundColor = ChatWALikeVC.filterMain == 0 ? .whatsappGreenLightColor : .whiteBubbleColor
            contAll.addTarget(self, action: #selector(selectFilter), for: .touchUpInside)
            
            contAll.addSubview(textAll)
            textAll.text = "All".localized()
            textAll.font = .boldSystemFont(ofSize: 14)
            textAll.textColor = ChatWALikeVC.filterMain == 0 ? .whatsappGreenTitleColor : .grayTitleColor
            textAll.anchor(left: contAll.leftAnchor, right: contAll.rightAnchor, paddingLeft: 15, paddingRight: 15, centerX: contAll.centerXAnchor, centerY: contAll.centerYAnchor, height: 20)
            
            header.addSubview(contUnread)
            contUnread.anchor(top: header.topAnchor, left: contAll.rightAnchor, bottom: header.bottomAnchor, paddingLeft: 8, height: 30)
            contUnread.layer.cornerRadius = 15
            contUnread.clipsToBounds = true
            contUnread.tag = 1
            contUnread.backgroundColor = ChatWALikeVC.filterMain == 1 ? .whatsappGreenLightColor : .whiteBubbleColor
            contUnread.addTarget(self, action: #selector(selectFilter), for: .touchUpInside)
            
            contUnread.addSubview(textUnread)
            textUnread.text = "Unread".localized()
            textUnread.font = .boldSystemFont(ofSize: 14)
            textUnread.textColor = ChatWALikeVC.filterMain == 1 ? .whatsappGreenTitleColor : .grayTitleColor
            textUnread.anchor(left: contUnread.leftAnchor, right: contUnread.rightAnchor, paddingLeft: 15, paddingRight: 15, centerX: contUnread.centerXAnchor, centerY: contUnread.centerYAnchor, height: 20)
            
            header.addSubview(contGroups)
            contGroups.anchor(top: header.topAnchor, left: contUnread.rightAnchor, bottom: header.bottomAnchor, paddingLeft: 8, height: 30)
            contGroups.layer.cornerRadius = 15
            contGroups.clipsToBounds = true
            contGroups.tag = 2
            contGroups.backgroundColor = ChatWALikeVC.filterMain == 2 ? .whatsappGreenLightColor : .whiteBubbleColor
            contGroups.addTarget(self, action: #selector(selectFilter), for: .touchUpInside)
            
            contGroups.addSubview(textGroups)
            textGroups.text = "Groups".localized()
            textGroups.font = .boldSystemFont(ofSize: 14)
            textGroups.textColor = ChatWALikeVC.filterMain == 2 ? .whatsappGreenTitleColor : .grayTitleColor
            textGroups.anchor(left: contGroups.leftAnchor, right: contGroups.rightAnchor, paddingLeft: 15, paddingRight: 15, centerX: contGroups.centerXAnchor, centerY: contGroups.centerYAnchor, height: 20)
        }
        
        return header
    }
    
    @objc func selectFilter(_ sender: UIButton) {
        if sender.tag == 0 && ChatWALikeVC.filterMain != 0 {
            ChatWALikeVC.filterMain = 0
            self.chats = self.tempChats
            self.tableView.reloadData()
        } else if sender.tag == 1 && ChatWALikeVC.filterMain != 1 {
            ChatWALikeVC.filterMain = 1
            self.chats = self.tempChats.filter({ Int($0.counter) ?? 0 > 0 })
            self.tableView.reloadData()
        }  else if sender.tag == 2 && ChatWALikeVC.filterMain != 2 {
            ChatWALikeVC.filterMain = 2
            self.chats = self.tempChats.filter({ !$0.groupId.isEmpty })
            self.tableView.reloadData()
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if fillteredData.count > 0 && selectedTag != UNREAD_TAG && selectedTag != 0 {
            if selectedTag == LINKS_TAG {
                return 160.0
            }
            return 130.0
        }
        let fontSize = Int(SecureUserDefaults.shared.value(forKey: "font_size") ?? "0")
        if fontSize == 4 {
            return 85.0
        } else if fontSize == 6 {
            return 95.0
        }
        return 75.0
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let sectionHeaderHeight: CGFloat = 30
        if scrollView.contentOffset.y <= sectionHeaderHeight && scrollView.contentOffset.y >= 0 {
            scrollView.contentInset.top = -scrollView.contentOffset.y
        } else if scrollView.contentOffset.y >= sectionHeaderHeight {
            scrollView.contentInset.top = -sectionHeaderHeight
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return fillteredData.count
        }
        return chats.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellChatWA", for: indexPath)
        let content = cell.contentView
        if content.subviews.count > 0 {
            content.subviews.forEach { $0.removeFromSuperview() }
        }
        let data: Chat
        if isFiltering {
            data = fillteredData[indexPath.row] as! Chat
        } else {
            if chats.count == 0 || (indexPath.row > (chats.count - 1)) {
                let labelNochat = UILabel()
                labelNochat.text = loadingData ? "Loading Data...".localized() : "There are no conversations".localized()
                labelNochat.font = .systemFont(ofSize: 13 + String.offset())
                labelNochat.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
                content.addSubview(labelNochat)
                labelNochat.anchor(centerX: content.centerXAnchor, centerY: content.centerYAnchor)
                cell.backgroundColor = .clear
                cell.selectionStyle = .none
                return cell
            }
            data = chats[indexPath.row]
        }
        if selectedTag != UNREAD_TAG && selectedTag != 0 {
            let title = UILabel()
            let subtitle = UILabel()
            title.textColor = .black
            subtitle.textColor = .gray
            title.font = .systemFont(ofSize: 16 + String.offset(), weight: .medium)
            subtitle.font = .systemFont(ofSize: 14 + String.offset())
            content.addSubview(title)
            content.addSubview(subtitle)
            title.anchor(top: content.topAnchor, left: content.leftAnchor, paddingTop: 10, paddingLeft: 20)
            subtitle.anchor(top: title.bottomAnchor, left: content.leftAnchor, right: content.rightAnchor, paddingLeft: 20, paddingRight: 20)
            subtitle.numberOfLines = 2
            title.text = data.name
            
            let imageArrowRight = UIImageView(image: UIImage(systemName: "chevron.right"))
            content.addSubview(imageArrowRight)
            imageArrowRight.tintColor = .gray
            imageArrowRight.anchor(top: content.topAnchor, right: content.rightAnchor, paddingTop: 10, paddingRight: 20)
            
            let timeView = UILabel()
            content.addSubview(timeView)
            timeView.anchor(top: content.topAnchor, right: imageArrowRight.leftAnchor, paddingTop: 10, paddingRight: 20)
            timeView.textColor = .gray
            timeView.font = UIFont.systemFont(ofSize: 16 + String.offset())
            
            let date = Date(milliseconds: Int64(data.serverDate)!)
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
            
            cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
            
            let container = UIView()
            content.addSubview(container)
            container.anchor(top: subtitle.bottomAnchor, left: content.leftAnchor, right: content.rightAnchor, paddingTop: 5, paddingLeft: 20, paddingRight: 20, height: selectedTag == LINKS_TAG ? 75 : 60)
            container.backgroundColor = .lightGray.withAlphaComponent(0.3)
            container.layer.cornerRadius = 15
            container.clipsToBounds = true
            container.isUserInteractionEnabled = true
            
            if selectedTag == DOCUMENTS_TAG {
                subtitle.text = "📄 " + "Document".localized()
                
                let imageFile = UIImageView(image: UIImage(systemName: "doc.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 45)))
                container.addSubview(imageFile)
                imageFile.tintColor = .black
                imageFile.anchor(top: container.topAnchor, left: container.leftAnchor, bottom: container.bottomAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, width: 45)
                
                let nameFile = UILabel()
                container.addSubview(nameFile)
                nameFile.font = .systemFont(ofSize: 12 + String.offset(), weight: .medium)
                nameFile.textColor = .black
                nameFile.numberOfLines = 2
                nameFile.anchor(top: container.topAnchor, left: imageFile.rightAnchor, right: container.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingRight: 5)
                nameFile.text = data.messageText.components(separatedBy: "|")[0]
                
                let fileSub = UILabel()
                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                let arrExtFile = (data.messageText.components(separatedBy: "|")[0]).split(separator: ".")
                let finalExtFile = arrExtFile[arrExtFile.count - 1]
                if let dirPath = paths.first {
                    let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(data.file)
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        if let dataFile = try? Data(contentsOf: fileURL) {
                            var sizeOfFile = Int(dataFile.count / 1000000)
                            if (sizeOfFile < 1) {
                                sizeOfFile = Int(dataFile.count / 1000)
                                if (finalExtFile.count > 4) {
                                    fileSub.text = "\(sizeOfFile) kB \u{2022} TXT"
                                }else {
                                    fileSub.text = "\(sizeOfFile) kB \u{2022} \(finalExtFile.uppercased())"
                                }
                            } else {
                                if (finalExtFile.count > 4) {
                                    fileSub.text = "\(sizeOfFile) MB \u{2022} TXT"
                                }else {
                                    fileSub.text = "\(sizeOfFile) MB \u{2022} \(finalExtFile.uppercased())"
                                }
                            }
                        } else {
                            fileSub.text = ""
                        }
                    }
                    else if FileEncryption.shared.isSecureExists(filename: data.file) {
                        if var dataFile = try? FileEncryption.shared.readSecure(filename: data.file) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: dataFile)
                            if dataDecrypt != nil {
                                dataFile = dataDecrypt!
                            }
                            var sizeOfFile = Int(dataFile.count / 1000000)
                            if (sizeOfFile < 1) {
                                sizeOfFile = Int(dataFile.count / 1000)
                                if (finalExtFile.count > 4) {
                                    fileSub.text = "\(sizeOfFile) kB \u{2022} TXT"
                                }else {
                                    fileSub.text = "\(sizeOfFile) kB \u{2022} \(finalExtFile.uppercased())"
                                }
                            } else {
                                if (finalExtFile.count > 4) {
                                    fileSub.text = "\(sizeOfFile) MB \u{2022} TXT"
                                }else {
                                    fileSub.text = "\(sizeOfFile) MB \u{2022} \(finalExtFile.uppercased())"
                                }
                            }
                        } else {
                            fileSub.text = ""
                        }
                    }
                    container.addSubview(fileSub)
                    fileSub.anchor(top: nameFile.bottomAnchor, left: imageFile.rightAnchor, bottom: container.bottomAnchor, paddingLeft: 10, paddingBottom: 5)
                    fileSub.font = .systemFont(ofSize: 10 + String.offset())
                    fileSub.textColor = .gray
                    let objectTap = ObjectGesture(target: self, action: #selector(onContSearch(_:)))
                    objectTap.file_id = data.file
                    container.addGestureRecognizer(objectTap)
                }
            } else if selectedTag == LINKS_TAG {
                var text = ""
                var txtData = data.messageText
                if txtData.contains("■"){
                    txtData = txtData.components(separatedBy: "■")[0]
                    txtData = txtData.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                let listTextSplitBreak = txtData.components(separatedBy: "\n")
                let indexFirstLinkSplitBreak = listTextSplitBreak.firstIndex(where: { $0.contains("www.") || $0.contains("http://") || $0.contains("https://") })
                if indexFirstLinkSplitBreak != nil {
                    let listTextSplitSpace = listTextSplitBreak[indexFirstLinkSplitBreak!].components(separatedBy: " ")
                    let indexFirstLinkSplitSpace = listTextSplitSpace.firstIndex(where: { ($0.starts(with: "www.") && $0.components(separatedBy: ".").count > 2) || ($0.starts(with: "http://") && $0.components(separatedBy: ".").count > 1) || ($0.starts(with: "https://") && $0.components(separatedBy: ".").count > 1) })
                    if indexFirstLinkSplitSpace != nil {
                        text = listTextSplitSpace[indexFirstLinkSplitSpace!]
                    }
                }
                var dataURL = ""
                subtitle.text = txtData
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
                
                var title = ""
                var description = ""
                var imageUrl: String?
                var link = text
                
                let objectTap = ObjectGesture(target: self, action: #selector(onContSearch(_:)))
                objectTap.message_id = link
                container.addGestureRecognizer(objectTap)
                
                let imagePreview = UIImageView()
                container.addSubview(imagePreview)
                imagePreview.translatesAutoresizingMaskIntoConstraints = false
                imagePreview.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
                imagePreview.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
                imagePreview.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
                imagePreview.widthAnchor.constraint(equalToConstant: 80.0).isActive = true
                
                imagePreview.image = UIImage(systemName: "link", withConfiguration: UIImage.SymbolConfiguration(pointSize: 45))
                imagePreview.contentMode = .center
                imagePreview.clipsToBounds = true
                imagePreview.tintColor = .black
                imagePreview.backgroundColor = .gray.withAlphaComponent(0.3)
                
                let titlePreview = UILabel()
                container.addSubview(titlePreview)
                titlePreview.translatesAutoresizingMaskIntoConstraints = false
                titlePreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
                titlePreview.topAnchor.constraint(equalTo: container.topAnchor, constant: 10.0).isActive = true
                titlePreview.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -5.0).isActive = true
                titlePreview.text = title
                titlePreview.font = UIFont.systemFont(ofSize: 14.0 + String.offset(), weight: .bold)
                titlePreview.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
                
                let descPreview = UILabel()
                container.addSubview(descPreview)
                descPreview.translatesAutoresizingMaskIntoConstraints = false
                descPreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
                descPreview.topAnchor.constraint(equalTo: titlePreview.bottomAnchor).isActive = true
                descPreview.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -5.0).isActive = true
                descPreview.text = description
                descPreview.font = UIFont.systemFont(ofSize: 12.0 + String.offset())
                descPreview.textColor = .gray
                descPreview.numberOfLines = 1
                
                let linkPreview = UILabel()
                container.addSubview(linkPreview)
                linkPreview.translatesAutoresizingMaskIntoConstraints = false
                linkPreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
                linkPreview.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -5.0).isActive = true
                linkPreview.font = UIFont.systemFont(ofSize: 10.0 + String.offset())
                linkPreview.textColor = .gray
                linkPreview.numberOfLines = 1
                
                if !dataURL.isEmpty {
                    if let data = try! JSONSerialization.jsonObject(with: dataURL.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                        title = data["title"] as! String
                        description = data["description"] as! String
                        imageUrl = data["imageUrl"] as? String
                        link = data["link"] as! String
                        
                        if imageUrl != nil {
                            imagePreview.loadImageAsync(with: imageUrl)
                            imagePreview.contentMode = .scaleToFill
                            imagePreview.clipsToBounds = true
                        }
                        
                        titlePreview.text = title
                        descPreview.text = description
                        linkPreview.text = link
                        linkPreview.topAnchor.constraint(equalTo: descPreview.bottomAnchor, constant: 8.0).isActive = true
                    }
                } else {
                    linkPreview.text = link
                    linkPreview.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
                }
            } else if selectedTag == AUDIOS_TAG {
                subtitle.text = "♫ " + "Audio".localized()
                
                let imageAudio = UIImageView()
                imageAudio.image = UIImage(systemName: "music.note", withConfiguration: UIImage.SymbolConfiguration(pointSize: 35))
                container.addSubview(imageAudio)
                imageAudio.anchor(left: container.leftAnchor, paddingLeft: 10, centerY: container.centerYAnchor)
                imageAudio.tintColor = .black
                
                let nameAudio = UILabel()
                container.addSubview(nameAudio)
                nameAudio.anchor(left: imageAudio.rightAnchor, right: container.rightAnchor, paddingLeft: 10, paddingRight: 10, centerY: container.centerYAnchor)
                nameAudio.numberOfLines = 2
                nameAudio.text = data.messageText.components(separatedBy: "|")[0]
                nameAudio.font = .systemFont(ofSize: 16 + String.offset(), weight: .medium)
                
                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                if let dirPath = paths.first {
                    let audioURL = URL(fileURLWithPath: dirPath).appendingPathComponent(data.audio)
                    if !FileManager.default.fileExists(atPath: audioURL.path) && !FileEncryption.shared.isSecureExists(filename: data.audio) {
                        Download().startHTTP(forKey: data.audio, isImage: false) { (name, progress) in
                            guard progress == 100 else {
                                return
                            }
                            tableView.reloadRows(at: [indexPath], with: .none)
                        }
                    } else {
                        let objectTap = ObjectGesture(target: self, action: #selector(onContSearch(_:)))
                        objectTap.audio_id = data.audio
                        container.addGestureRecognizer(objectTap)
                    }
                }
            }
            return cell
        }
        
        let imageView = UIImageView()
        content.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 55.0),
            imageView.heightAnchor.constraint(equalToConstant: 55.0)
        ])
        var leadingAnchor = imageView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20.0)
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
                    getImage(name: data.profile, placeholderImage: UIImage(named: data.pin == "-999" ? "pb_button" : (data.messageScope == MessageScope.WHISPER || data.messageScope == MessageScope.CALL || data.messageScope == MessageScope.MISSED_CALL) ? "Profile---Purple" : "Conversation---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                        imageView.image = image
                    })
                } else {
                    leadingAnchor = imageView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 40.0)
                    let image = UIImage(named: "Conversation---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
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
            if Int(data.counter)! > 99 {
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
        cell.separatorInset = UIEdgeInsets(top: 0, left: 85, bottom: 0, right: 0)
        return cell
    }
    
    @objc func onContSearch(_ sender: ObjectGesture) {
        if selectedTag == PHOTOS_TAG {
            
        } else if selectedTag == VIDEOS_TAG {
            
        } else if selectedTag == DOCUMENTS_TAG {
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
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
                        if var docData = try FileEncryption.shared.readSecure(filename: sender.file_id) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: docData)
                            if dataDecrypt != nil {
                                docData = dataDecrypt!
                            }
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
                }
            }
        } else if selectedTag == LINKS_TAG {
            var stringURl = sender.message_id
            if stringURl.lowercased().starts(with: "www.") {
                stringURl = "https://" + stringURl.replacingOccurrences(of: "www.", with: "")
            }
            guard let url = URL(string: stringURl) else { return }
            if Nexilis.checkingAccess(key: "secure_browser") {
                APIS.openUrl(url: stringURl)
            } else {
                guard let url = URL(string: stringURl) else { return }
                UIApplication.shared.open(url)
            }
        } else if selectedTag == AUDIOS_TAG {
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let audioURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.audio_id)
                if FileManager.default.fileExists(atPath: audioURL.path) {
                    do {
                        if audioPlayer == nil || audioPlayer?.url != audioURL {
                            do {
                                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                                try AVAudioSession.sharedInstance().setActive(true)
                            } catch {
                                
                            }
                            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                            audioPlayer?.prepareToPlay()
                            audioPlayer?.play()
                        } else if audioPlayer!.isPlaying {
                            audioPlayer?.pause()
                        } else {
                            audioPlayer?.play()
                        }
                    } catch {
                        
                    }
                } else if FileEncryption.shared.isSecureExists(filename: sender.audio_id) {
                    do {
                        if var audioData = try FileEncryption.shared.readSecure(filename: sender.audio_id) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: audioData)
                            if dataDecrypt != nil {
                                audioData = dataDecrypt!
                            }
                            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                            let tempPath = cachesDirectory.appendingPathComponent(sender.audio_id)
                            try audioData.write(to: tempPath)
                            if audioPlayer == nil || audioPlayer?.url != tempPath {
                                do {
                                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                                    try AVAudioSession.sharedInstance().setActive(true)
                                } catch {
                                    
                                }
                                audioPlayer = try AVAudioPlayer(contentsOf: tempPath)
                                audioPlayer?.prepareToPlay()
                                audioPlayer?.play()
                            } else if audioPlayer!.isPlaying {
                                audioPlayer?.pause()
                            } else {
                                audioPlayer?.play()
                            }
                        }
                    } catch {
                        
                    }
                }
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let data: Chat
        if isFiltering {
            data = fillteredData[indexPath.row] as! Chat
        } else {
            data = chats[indexPath.row]
        }
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
        let data: Chat
        if isFiltering || selectedTag == UNREAD_TAG {
            data = fillteredData[indexPath.row] as! Chat
        } else {
            data = chats[indexPath.row]
        }
        data.isSelected = !data.isSelected
        if data.isSelected {
            if let dataSubChats = self.chatGroupMaps[data.groupId] {
                for dataSubChat in dataSubChats {
                    if var indexParent = chats.firstIndex(where: { $0.isParent && $0.groupId == data.groupId }) {
                        if isFiltering || selectedTag == UNREAD_TAG {
                            if var indexParentFilter = fillteredData.firstIndex(where: { ($0 as! Chat).isParent && ($0 as! Chat).groupId == data.groupId }) {
                                fillteredData.insert(dataSubChat, at: indexParentFilter + 1)
                                indexParentFilter+=1
                            }
                        } else {
                            chats.insert(dataSubChat, at: indexParent + 1)
                            indexParent+=1
                            if var indexParentFilter = tempChats.firstIndex(where: { $0.isParent && $0.groupId == data.groupId }) {
                                tempChats.insert(dataSubChat, at: indexParentFilter + 1)
                                indexParentFilter+=1
                            }
                        }
                    }
                    
                }
            }
        } else {
            if isFiltering || selectedTag == UNREAD_TAG {
                if var changedFillteredData = fillteredData as? [Chat] {
                    changedFillteredData.removeAll(where: { $0.isParent == false && $0.groupId == data.groupId })
                    self.fillteredData = changedFillteredData
                }
            } else {
                chats.removeAll(where: { $0.isParent == false && $0.groupId == data.groupId })
                tempChats.removeAll(where: { $0.isParent == false && $0.groupId == data.groupId })
            }
        }
        tableView.reloadData()
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
    
    public func updateSearchResults(for searchController: UISearchController) {
    }
    
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.previewItem != nil ? 1 : 0
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
        return self.previewItem!
    }
}
