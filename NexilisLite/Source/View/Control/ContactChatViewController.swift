//
//  ContactChatViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 22/09/21.
//

import UIKit
import FMDB
import NotificationBannerSwift
import Toast_Swift

class ContactChatViewController: UITableViewController {
    
    deinit {
        //print(#function, ">>>> TADAA")
        NotificationCenter.default.removeObserver(self)
    }
    
    var isChooser: ((String, String) -> ())?
    
    var isAdmin: Bool = false
    
    var chats: [Chat] = []
    
    var archivedChats: [Chat] = []
    var listMaxArchived: [String: [String]] = [:]
    
    var chatGroupMaps: [String: [Chat]] = [:]
    
    var contacts: [User] = []
    
    var groups: [Group] = []
    
    var groupMap: [String:Int] = [:]
    
    var searchController: UISearchController!
    
    var segment: UISegmentedControl!
    
    var fillteredData: [Any] = []
    
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isFiltering: Bool {
        return !isSearchBarEmpty
    }
    
    var noData = false
    
    var loadingData = true
    var isGettingData = false
    var timerReloadData: Timer?
    
    var noUCList = false
    
    func filterContentForSearchText(_ searchText: String) {
        func filterContact() {
            Utils.inTabChats = false
            fillteredData = self.contacts.filter { $0.fullName.lowercased().contains(searchText.lowercased()) }
        }
        func filterGroup() {
            Utils.inTabChats = false
            fillteredData = self.groups.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        if !searchText.isEmpty {
            if segment.numberOfSegments == 3 {
                switch segment.selectedSegmentIndex {
                case 1:
                    fillteredData = self.contacts.filter { $0.fullName.lowercased().contains(searchText.lowercased()) }
                case 2:
                    fillteredData = self.groups.filter { $0.name.lowercased().contains(searchText.lowercased()) }
                default:
                    var group_id: String?
                    if let filterGroupKey = self.chatGroupMaps.first(where: { $0.value.contains { $0.name.lowercased().contains(searchText.lowercased()) || $0.groupName.lowercased().contains(searchText.lowercased()) || $0.messageText.lowercased().contains(searchText.lowercased()) } } ) {
                        group_id = filterGroupKey.key
                    }
                    let deepCopyChats = self.chats.map{ $0.copy() }
                    fillteredData = deepCopyChats.filter { $0.name.lowercased().contains(searchText.lowercased()) || $0.messageText.lowercased().contains(searchText.lowercased()) || $0.groupId == group_id }
                }
            } else {
                switch segment.selectedSegmentIndex {
                case 1:
                    filterGroup()
                default:
                    filterContact()
                }
            }
        }
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let me = User.getMyPin()!
        Database.shared.database?.inTransaction({ fmdb, rollback in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select FIRST_NAME, LAST_NAME, IMAGE_ID, USER_TYPE from BUDDY where F_PIN = '\(me)'"), cursor.next() {
                    isAdmin = cursor.string(forColumnIndex: 3) == "23" || cursor.string(forColumnIndex: 3) == "24"
                    cursor.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        
        //        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(cancel(sender:)))
        
        let childrenMenu : [UIAction] = [
            UIAction(title: "Create Group".localized(), image: UIImage(systemName: "person.and.person"), handler: {[weak self](_) in
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "createGroupNav") as! UINavigationController
                Utils.addBackground(view: controller.view)
                let vc = controller.topViewController as! GroupCreateViewController
                vc.isDismiss = { id in
                    self?.groupMap.removeAll()
                    let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "groupDetailView") as! GroupDetailViewController
                    controller.data = id
                    self?.navigationController?.show(controller, sender: nil)
                }
                self?.navigationController?.present(controller, animated: true, completion: nil)
            }),
            UIAction(title: "Add Friends".localized(), image: UIImage(systemName: "person.badge.plus"), handler: {[weak self](_) in
                self?.addFriend(sender: UIBarButtonItem())
            }),
//            UIAction(title: "Configure Email", image: UIImage(systemName: "mail"), handler: {[weak self](_) in
//
//            }),
            UIAction(title: "Favorite Messages".localized(), image: UIImage(systemName: "star"), handler: {[weak self](_) in
                let editorStaredVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "staredVC") as! EditorStarMessages
                self?.navigationController?.show(editorStaredVC, sender: nil)
            }),
        ]
        //debug only
//        isAdmin = true
//        if(isAdmin){
//            childrenMenu.append(UIAction(title: "Broadcast Message".localized(), image: UIImage(systemName: "envelope.open"), handler: {[weak self](_) in
//                let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "broadcastNav")
//                controller.modalPresentationStyle = .fullScreen
//                self?.navigationController?.present(controller, animated: true, completion: nil)
//            }))
//            childrenMenu.append(UIAction(title: "Live Streaming".localized(), image: UIImage(systemName: "video.bubble.left"), handler: {[weak self](_) in
//                let navigationController = CustomNavigationController(rootViewController: QmeraCreateStreamingViewController())
//                navigationController.modalPresentationStyle = .fullScreen
//                navigationController.navigationBar.tintColor = .white
//                navigationController.navigationBar.barTintColor = .mainColor
//                navigationController.navigationBar.isTranslucent = false
//                navigationController.navigationBar.overrideUserInterfaceStyle = .dark
//                navigationController.navigationBar.barStyle = .black
//                let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white]
//                UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
//                let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
//                navigationController.navigationBar.titleTextAttributes = textAttributes
//                navigationController.view.backgroundColor = .mainColor
//                self?.navigationController?.present(navigationController, animated: true, completion: nil)
//            }))
//        }
        
//        if noUCList {
//            let buttonAddFriend = UIBarButtonItem(image: UIImage(systemName: "person.badge.plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default))?.withTintColor(.white), style: .plain, target: self, action: #selector(addFriend(sender:)))
//            navigationItem.rightBarButtonItem = buttonAddFriend
//        } else {
//            let menu = UIMenu(title: "", children: childrenMenu)
//            navigationItem.rightBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "ellipsis"), primaryAction: .none, menu: menu)
//        }
        let menu = UIMenu(title: "", children: childrenMenu)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "ellipsis"), primaryAction: .none, menu: menu)
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
//        searchController.searchBar.setMagnifyingGlassColorTo(color: .white)
//        searchController.searchBar.updateHeight(height: 36, radius: 18)
        searchController.searchBar.setImage(UIImage(), for: .search, state: .normal)
        searchController.searchBar.setPositionAdjustment(UIOffset(horizontal: 10, vertical: 0), for: .search)
        if #unavailable(iOS 26.0) {
            searchController.searchBar.setCustomBackgroundImage(image: UIImage(named: self.traitCollection.userInterfaceStyle == .dark ? "nx_search_bar_dark" : "nx_search_bar", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        }
        searchController.searchBar.tintColor = .mainColor
        searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "Search".localized(), attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)])
        
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        definesPresentationContext = true
        
        var dataSegment = ["Chats".localized(), "Contacts".localized(), "Forums".localized()]
        if noUCList{
            dataSegment = ["Contacts".localized(), "Forums".localized()]
        }
        segment = UISegmentedControl(items: dataSegment)
        segment.sizeToFit()
        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: #selector(segmentChanged(sender:)), for: .valueChanged)
        segment.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12.0 + String.offset() * 0.5)], for: .normal)
        Utils.inTabChats = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(onStatusChat(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerStatusChat), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onReceiveMessage(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerReceiveChat), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onReload(notification:)), name: NSNotification.Name(rawValue: "onMember"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onReloadTab(notification:)), name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onReload(notification:)), name: NSNotification.Name(rawValue: "onUpdatePersonInfo"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onReloadTab(notification:)), name: NSNotification.Name(rawValue: "onTopic"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDisconnected(notification:)), name: NSNotification.Name(rawValue: "disconnected_nexilis"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDatabaseOpened(notification:)), name: NSNotification.Name(rawValue: "databaseOpened"), object: nil)
        
        tableView.tableHeaderView = segment
        tableView.tableFooterView = UIView()
        
        pullBuddy()
//        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0), NSAttributedString.Key.foregroundColor: UIColor.white]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
        navBarAppearance.titleTextAttributes = attributes
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
//        removeAllData()
//        getData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Utils.inTabChats = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isChooser != nil {
            self.navigationController?.navigationBar.topItem?.title = "Forward Messages".localized()
            self.navigationController?.navigationBar.setNeedsLayout()
        } else if noUCList{
            self.navigationController?.navigationBar.topItem?.title = "Start Chat".localized()
            self.navigationController?.navigationBar.setNeedsLayout()
        } else {
            self.navigationController?.navigationBar.topItem?.title = "Start Conversation".localized()
            self.navigationController?.navigationBar.setNeedsLayout()
        }
        getData()
        DispatchQueue.global().async {
            self.getOpenGroups(listGroups: self.groups, completion: { g in
                DispatchQueue.main.async {
                    self.groups.removeAll(where: { $0.isOpen == "1" && $0.groupType == "NOTJOINED" })
                    for og in g {
                        if self.groups.first(where: { $0.id == og.id }) == nil {
                            self.groups.append(og)
                        }
                    }
                    self.groups.sort { (a, b) -> Bool in
                        if Int(a.official) == 1 {
                            return true
                        } else if Int(b.official) == 1 {
                            return false
                        } else {
                            return Int(a.official) ?? 0 > Int(b.official) ?? 0
                        }
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            })
        }
        APIS.setDataForShareExtension()
    }
    
    @objc func addFriend(sender: UIBarButtonItem) {
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "addFriendNav") as! UINavigationController
        Utils.addBackground(view: controller.view)
        if let vc = controller.viewControllers.first as? AddFriendTableViewController {
            vc.isDismiss = {
                self.getContacts {
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
        navigationController?.present(controller, animated: true, completion: nil)
    }
    
//    func removeAllData() {
//        groups.removeAll()
//        groupMap.removeAll()
//        chats.removeAll()
//        tableView.reloadData()
//    }
    
    private func reloadAllData() {
//        print("reloadAllData")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.timerReloadData == nil && !self.isGettingData {
                self.getData()
            } else {
                self.timerReloadData?.invalidate()
                self.timerReloadData = nil
                self.timerReloadData = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                    if self != nil && !self!.isGettingData {
                        guard let self = self else { return }
                        self.getData()
                        self.timerReloadData = nil
                    }
                }
            }
        }
    }
    
    @objc func onDatabaseOpened(notification: NSNotification) {
        DispatchQueue.main.async {
            if self.loadingData {
                self.reloadAllData()
            }
        }
    }
    
    @objc func onDisconnected(notification: NSNotification) {
        DispatchQueue.main.async {
            self.loadingData = true
            self.chatGroupMaps.removeAll()
            self.chats.removeAll()
            self.contacts.removeAll()
            self.groups.removeAll()
            self.tableView.reloadData()
            self.reloadAllData()
        }
    }
    
    @objc func onReloadTab(notification: NSNotification) {
        reloadAllData()
    }
    
    @objc func onReload(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        if data["member"] as? String == User.getMyPin()! {
            reloadAllData()
        } else if data["state"] as? Int == 99 {
            reloadAllData()
        }
    }
    
    @objc func onReceiveMessage(notification: NSNotification) {
        reloadAllData()
    }
    
    @objc func onStatusChat(notification: NSNotification) {
        reloadAllData()
    }
    
    @objc func add(sender: Any) {
        
    }
    
    @objc func cancel(sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func segmentChanged(sender: Any) {
        switch segment.selectedSegmentIndex {
        case 0:
            if segment.numberOfSegments == 3 {
                Utils.inTabChats = true
            }
        case 1:
            Utils.inTabChats = false
            if segment.numberOfSegments < 3 {
                DispatchQueue.global().async {
                    self.getOpenGroups(listGroups: self.groups, completion: { g in
                        DispatchQueue.main.async {
                            for og in g {
                                if self.groups.first(where: { $0.id == og.id }) == nil {
                                    self.groups.append(og)
                                }
                            }
                            self.groups.sort { (a, b) -> Bool in
                                if Int(a.official) == 1 {
                                    return true
                                } else if Int(b.official) == 1 {
                                    return false
                                } else {
                                    return Int(a.official) ?? 0 > Int(b.official) ?? 0
                                }
                            }
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    })
                }
            }
        case 2:
            Utils.inTabChats = false
//            DispatchQueue.global().async {
//                self.getOpenGroups(listGroups: self.groups, completion: { g in
//                    DispatchQueue.main.async {
//                        for og in g {
//                            if self.groups.first(where: { $0.id == og.id }) == nil {
//                                self.groups.append(og)
//                            }
//                        }
//                        self.groups.sort { (a, b) -> Bool in
//                            if Int(a.official) == 1 {
//                                return true
//                            } else if Int(b.official) == 1 {
//                                return false
//                            } else {
//                                return Int(a.official) ?? 0 > Int(b.official) ?? 0
//                            }
//                        }
//                        DispatchQueue.main.async {
//                            self.tableView.reloadData()
//                        }
//                    }
//                })
//            }
        default:
            Utils.inTabChats = false
        }
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    // MARK: - Data source
    
    func getData() {
        if self.isGettingData {
            return
        }
        getChats {
            self.getContacts {
                self.getGroups { g1 in
                    self.groupMap.removeAll()
                    self.groups = g1
                    self.groups.sort { (a, b) -> Bool in
                        if Int(a.official) == 1 {
                            return true
                        } else if Int(b.official) == 1 {
                            return false
                        } else {
                            return Int(a.official) ?? 0 > Int(b.official) ?? 0
                        }
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.isGettingData = false
                    }
                }
            }
        }
    }
    
    func getChats(completion: @escaping ()->()) {
        DispatchQueue.global().async {
//            while self.isGettingData {
//                Thread.sleep(forTimeInterval: 0.1)
//            }
            self.isGettingData = true
            self.chatGroupMaps.removeAll()
            self.listMaxArchived.removeAll()
            let previousChat = self.chats
            let allChats = Chat.getData()
            self.archivedChats = Chat.getData(isArchived: true)
            var tempChats: [Chat] = []
            var lowestPinned: [String: Int64] = [:]

            for singleChat in allChats {
                guard !singleChat.groupId.isEmpty else {
                    tempChats.append(singleChat)
                    if singleChat.pinned > 0 {
                        self.listMaxArchived[singleChat.pin] = [""]
                    }
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
                        if singleChat.pinned != 0 && (lowestPinned[singleChat.groupId] == 0 || lowestPinned[singleChat.groupId]! > singleChat.pinned) {
                            lowestPinned[singleChat.groupId] = singleChat.pinned
                        }
                        if singleChat.pinned != 0 {
                            if !self.listMaxArchived.keys.contains(singleChat.groupId) {
                                self.listMaxArchived[singleChat.groupId] = [singleChat.pin]
                            } else {
                                self.listMaxArchived[singleChat.groupId]?.append(singleChat.pin)
                            }
                        }
                        if tempChats[parentChatIndex].pinned < singleChat.pinned {
                            tempChats[parentChatIndex].pinned = singleChat.pinned
                        }
                        if tempChats[parentChatIndex].pinned > 0 {
                            if singleChat.pinned == 0 {
                                singleChat.pinned = lowestPinned[singleChat.groupId]! - 1
                                singleChat.isFolPinned = true
                            }
                            tempChats.forEach { chat in
                                if chat.groupId == singleChat.groupId && (chat.pinned == 0 || (chat.isFolPinned && chat.pinned != lowestPinned[singleChat.groupId]! - 1)) {
                                    chat.pinned = lowestPinned[singleChat.groupId]! - 1
                                    chat.isFolPinned = true
                                }
                            }
                        }
                    }
                    
                    if let parentExist = chatParentInPreviousChats, parentExist.isSelected,
                       let indexParent = tempChats.firstIndex(where: { $0.isParent && $0.groupId == singleChat.groupId }) {
                        tempChats.insert(singleChat, at: min(indexParent + existingGroup.count, tempChats.count))
                    }
                } else {
                    if lowestPinned[singleChat.groupId] == nil {
                        lowestPinned[singleChat.groupId] = 0
                    }
                    if singleChat.pinned != 0 {
                        lowestPinned[singleChat.groupId] = singleChat.pinned
                    }
                    self.chatGroupMaps[singleChat.groupId] = [singleChat]
                    let parentChat = Chat(profile: singleChat.profile, groupName: singleChat.groupName, counter: singleChat.counter, groupId: singleChat.groupId)
                    parentChat.isParent = true
                    
                    if parentChat.pinned != singleChat.pinned {
                        parentChat.pinned = singleChat.pinned
                        self.listMaxArchived[singleChat.groupId] = [singleChat.pin]
                    }
                    
                    if let parentExist = chatParentInPreviousChats, parentExist.isSelected {
                        parentChat.isSelected = true
                        tempChats.append(parentChat)
                        tempChats.append(singleChat)
                    } else {
                        tempChats.append(parentChat)
                    }
                }
            }
            if self.isChooser != nil {
                tempChats.removeAll(where: { $0.pin == "-997" })
            }
            tempChats.sort(by: { $0.pinned > $1.pinned })
            if self.archivedChats.count > 0 {
                tempChats.insert(Chat(pin: "Archived"), at: 0)
            }
            self.chats = tempChats
            completion()
        }
    }
    
    private func getContacts(completion: @escaping ()->()) {
        self.contacts.removeAll()
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    if self.isChooser == nil {
                        let gptUser = User(pin: "-997",
                                        firstName: Utils.getGPTBotName(),
                                        lastName: "",
                                        thumb: "",
                                        userType: "0",
                                        official: "1")
                        self.contacts.append(gptUser)
                    }
                    if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_pin, first_name, last_name, image_id, official_account, user_type FROM BUDDY where f_pin <> '\(User.getMyPin()!)' order by 5 desc, 2 collate nocase asc") {
                        while cursorData.next() {
                            let user = User(pin: cursorData.string(forColumnIndex: 0) ?? "",
                                            firstName: cursorData.string(forColumnIndex: 1) ?? "",
                                            lastName: cursorData.string(forColumnIndex: 2) ?? "",
                                            thumb: cursorData.string(forColumnIndex: 3) ?? "",
                                            userType: cursorData.string(forColumnIndex: 5) ?? "")
                            if (user.firstName + " " + user.lastName).trimmingCharacters(in: .whitespaces) == "USR\(user.pin)" {
                                continue
                            }
                            user.official = cursorData.string(forColumnIndex: 4) ?? ""
                            if !self.contacts.contains(where: {$0.pin == user.pin}) {
                                self.contacts.append(user)
                            }
                        }
                        cursorData.close()
                    }
                    completion()
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        }
    }
    
    private func getGroupRecursive(fmdb: FMDatabase, id: String = "", parent: String = "") -> [Group] {
        var data: [Group] = []
        var query = "select g.group_id, g.f_name, g.image_id, g.quote, g.created_by, g.created_date, g.parent, g.group_type, g.is_open, g.official, g.is_education, g.level, g.chat_modifier from GROUPZ g where "
        if id.isEmpty {
            query += "g.parent = '\(parent)'"
        } else {
            query += "g.group_id = '\(id)'"
        }
        query += "order by 12 asc, 13 asc, 2 asc"
        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: query) {
            while cursor.next() {
                let group = Group(
                    id: cursor.string(forColumnIndex: 0) ?? "",
                    name: cursor.string(forColumnIndex: 1) ?? "",
                    profile: cursor.string(forColumnIndex: 2) ?? "",
                    quote: cursor.string(forColumnIndex: 3) ?? "",
                    by: cursor.string(forColumnIndex: 4) ?? "",
                    date: cursor.string(forColumnIndex: 5) ?? "",
                    parent: cursor.string(forColumnIndex: 6) ?? "",
                    chatId: "",
                    groupType: cursor.string(forColumnIndex: 7) ?? "",
                    isOpen: cursor.string(forColumnIndex: 8) ?? "",
                    official: cursor.string(forColumnIndex: 9) ?? "",
                    isEducation: cursor.string(forColumnIndex: 10) ?? "",
                    level: cursor.string(forColumnIndex: 11) ?? "",
                    chatModifier: cursor.string(forColumnIndex: 12) ?? "")
                
                if group.chatId.isEmpty {
                    let lounge = Group(id: group.id, name: "Lounge".localized(), profile: "", quote: group.quote, by: group.by, date: group.date, parent: group.id, chatId: group.chatId, groupType: group.groupType, isOpen: group.isOpen, official: group.official, isEducation: group.isEducation, isLounge: true, level: group.level != "-1" ? group.level : "2")
                    group.childs.append(lounge)
                }
                
                if let topicCursor = Database.shared.getRecords(fmdb: fmdb, query: "select chat_id, title, thumb from DISCUSSION_FORUM where group_id = '\(group.id)'") {
                    while topicCursor.next() {
                        let topic = Group(id: group.id,
                                          name: topicCursor.string(forColumnIndex: 1) ?? "",
                                          profile: topicCursor.string(forColumnIndex: 2) ?? "",
                                          quote: group.quote,
                                          by: group.by,
                                          date: group.date,
                                          parent: group.id,
                                          chatId: topicCursor.string(forColumnIndex: 0) ?? "",
                                          groupType: group.groupType,
                                          isOpen: group.isOpen,
                                          official: group.official,
                                          isEducation: group.isEducation,
                                          level: group.level != "-1" ? group.level : "2")
                        group.childs.append(topic)
                    }
                    topicCursor.close()
                }
                
                if !parent.isEmpty {
                    _ = Nexilis.write(message: CoreMessage_TMessageBank.getRequestGroupWithoutMemberFromParent(fPin: User.getMyPin() ?? "", groupId: parent))
                }
                
                if !group.id.isEmpty {
//                    if group.official == "1" {
//                        let idMe = User.getMyPin() as String?
//                        if let cursorUser = Database.shared.getRecords(fmdb: fmdb, query: "SELECT user_type FROM BUDDY where f_pin='\(idMe!)'"), cursorUser.next() {
////                            if cursorUser.string(forColumnIndex: 0) == "23" || cursorUser.string(forColumnIndex: 0) == "24" {
////                                group.childs.append(contentsOf: getGroupRecursive(fmdb: fmdb, parent: group.id))
////                            }
//                            group.childs.append(contentsOf: getGroupRecursive(fmdb: fmdb, parent: group.id))
//                            cursorUser.close()
//                        }
//                    } else if group.official != "1"{
//                        group.childs.append(contentsOf: getGroupRecursive(fmdb: fmdb, parent: group.id))
//                    }
                    group.childs.append(contentsOf: getGroupRecursive(fmdb: fmdb, parent: group.id))
//                    group.childs = group.childs.sorted(by: { $0.name < $1.name })
//                    let dataLounge = group.childs.filter({$0.name == "Lounge".localized()})
//                    group.childs = group.childs.filter({ $0.name != "Lounge".localized() })
//                    group.childs.insert(contentsOf: dataLounge, at: 0)
                }
                data.append(group)
            }
            cursor.close()
        }
        return data
    }
    
    private func getOpenGroups(listGroups: [Group], completion: @escaping ([Group]) -> (), retry: Int = 3) {
        if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getOpenGroups(p_account: "1,2,3,5,6,7", offset: "0", search: "")) {
            var dataGroups: [Group] = []
            if (response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "00") {
                let data = response.getBody(key: CoreMessage_TMessageKey.DATA)
                if let json = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: []) as? [[String: Any?]] {
                    for dataJson in json {
                        let group = Group(
                            id: dataJson[CoreMessage_TMessageKey.GROUP_ID] as? String ?? "",
                            name: dataJson[CoreMessage_TMessageKey.GROUP_NAME] as? String ?? "",
                            profile: dataJson[CoreMessage_TMessageKey.THUMB_ID] as? String ?? "",
                            quote: dataJson[CoreMessage_TMessageKey.QUOTE] as? String ?? "",
                            by: dataJson[CoreMessage_TMessageKey.BLOCK] as? String ?? "",
                            date: "",
                            parent: "",
                            chatId: "",
                            groupType: "NOTJOINED",
                            isOpen: dataJson[CoreMessage_TMessageKey.IS_OPEN] as? String ?? "",
                            official: "0",
                            isEducation: "")
                        dataGroups.append(group)
                    }
                    completion(dataGroups)
                } else {
                    if retry != 0 {
                        getOpenGroups(listGroups: listGroups, completion: completion, retry: retry - 1)
                    }
                }
            } else {
                if retry != 0 {
                    getOpenGroups(listGroups: listGroups, completion: completion, retry: retry - 1)
                }
            }
        } else {
            if retry != 0 {
                getOpenGroups(listGroups: listGroups, completion: completion, retry: retry - 1)
            }
        }
    }
    
    private func getGroups(id: String = "", parent: String = "", completion: @escaping ([Group]) -> ()) {
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ fmdb, rollback in
                do {
                    completion(self.getGroupRecursive(fmdb: fmdb, id: id, parent: parent))
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        }
    }
    
    private func pullBuddy() {
        if let me = User.getMyPin() {
            DispatchQueue.global().async {
                let _ = Nexilis.write(message: CoreMessage_TMessageBank.getBatchBuddiesInfos(p_f_pin: me, last_update: 0))
            }
        }
    }
    
    private func joinOpenGroup(groupId: String, flagMember: String = "0", completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            var result: Bool = false
            let idMe = User.getMyPin() as String?
            if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getAddGroupMember(p_group_id: groupId, p_member_pin: idMe!, p_position: "0")), response.isOk() {
                result = true
            }
            completion(result)
        }
    }
    
}

// MARK: - Table view data source

extension ContactChatViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if noData {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        func selectOnContact() {
            let data: User
            if isFiltering {
                data = fillteredData[indexPath.row] as! User
            } else {
                data = contacts[indexPath.row]
            }
            if data.pin == "-997" {
                let smartChatVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "chatGptVC") as! ChatGPTBotView
                smartChatVC.hidesBottomBarWhenPushed = true
                smartChatVC.fromNotification = false
                navigationController?.show(smartChatVC, sender: nil)
                return
            }
            if let chooser = isChooser {
                var exblock = User.getDataCanNil(pin: data.pin)?.ex_block
                exblock = exblock == nil ? "0" : exblock!.isEmpty ? "0" : exblock!
                if exblock != "0" {
                    if exblock == "1" {
                        self.view.makeToast("You blocked this user".localized(), duration: 3)
                    } else {
                        self.view.makeToast("You have been blocked by this user".localized(), duration: 3)
                    }
                    return
                }
                chooser("3", data.pin)
                dismiss(animated: true, completion: nil)
                return
            }
            let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
            editorPersonalVC.hidesBottomBarWhenPushed = true
            editorPersonalVC.unique_l_pin = data.pin
            navigationController?.show(editorPersonalVC, sender: nil)
        }
        if segment.numberOfSegments == 3 {
            switch segment.selectedSegmentIndex {
            case 0:
                let data: Chat
                if isFiltering {
                    data = fillteredData[indexPath.row] as! Chat
                } else {
                    data = chats[indexPath.row]
                }
                if self.archivedChats.count > 0 && indexPath.row == 0 {
                    let controller = ArchivedChatView()
                    controller.archivedChats = archivedChats
                    controller.hidesBottomBarWhenPushed = true
                    navigationController?.show(controller, sender: nil)
                    return
                }
                if data.isParent {
                    expandCollapseChats(tableView: tableView, indexPath: indexPath)
                    return
                }
                if let chooser = isChooser {
                    var exblock = User.getDataCanNil(pin: data.pin)?.ex_block
                    exblock = exblock == nil ? "0" : exblock!.isEmpty ? "0" : exblock!
                    if exblock != "0" {
                        if exblock == "1" {
                            self.view.makeToast("You blocked this user".localized(), duration: 3)
                        } else {
                            self.view.makeToast("You have been blocked by this user".localized(), duration: 3)
                        }
                        return
                    }
                    if data.pin == "-999"{
                        return
                    }
                    chooser(data.messageScope, data.pin)
                    dismiss(animated: true, completion: nil)
                    return
                }
                if data.pin == "-997" {
                    let smartChatVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "chatGptVC") as! ChatGPTBotView
                    smartChatVC.hidesBottomBarWhenPushed = true
                    smartChatVC.fromNotification = false
                    navigationController?.show(smartChatVC, sender: nil)
                } else if data.messageScope == MessageScope.WHISPER || data.messageScope == MessageScope.CALL || data.messageScope == MessageScope.MISSED_CALL {
                    let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                    editorPersonalVC.hidesBottomBarWhenPushed = true
                    editorPersonalVC.unique_l_pin = data.pin
                    navigationController?.show(editorPersonalVC, sender: nil)
                } else {
                    groupMap.removeAll()
                    let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                    editorGroupVC.hidesBottomBarWhenPushed = true
                    editorGroupVC.unique_l_pin = data.pin
                    navigationController?.show(editorGroupVC, sender: nil)
                }
            case 1:
                selectOnContact()
            case 2:
                expandCollapseGroup(tableView: tableView, indexPath: indexPath)
            default:
                let data = contacts[indexPath.row]
                let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                editorPersonalVC.hidesBottomBarWhenPushed = true
                editorPersonalVC.unique_l_pin = data.pin
                navigationController?.show(editorPersonalVC, sender: nil)
            }
        } else {
            switch segment.selectedSegmentIndex {
            case 0:
                selectOnContact()
            case 1:
                expandCollapseGroup(tableView: tableView, indexPath: indexPath)
            default:
                let data = contacts[indexPath.row]
                let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                editorPersonalVC.hidesBottomBarWhenPushed = true
                editorPersonalVC.unique_l_pin = data.pin
                navigationController?.show(editorPersonalVC, sender: nil)
            }
        }
    }
    
    func expandCollapseChats(tableView: UITableView, indexPath: IndexPath) {
        let data: Chat
        if isFiltering {
            data = fillteredData[indexPath.row] as! Chat
        } else {
            data = chats[indexPath.row]
        }
        data.isSelected = !data.isSelected
        if data.isSelected {
            if let dataSubChats = self.chatGroupMaps[data.groupId] {
                for dataSubChat in dataSubChats {
                    if var indexParent = chats.firstIndex(where: { $0.isParent && $0.groupId == data.groupId }) {
                        if isFiltering {
                            fillteredData.insert(dataSubChat, at: indexParent + 1)
                            indexParent+=1
                        } else {
                            chats.insert(dataSubChat, at: indexParent + 1)
                            indexParent+=1
                            chats.sort(by: { $0.pinned > $1.pinned })
                        }
                    }
                    
                }
            }
        } else {
            if isFiltering {
                if var changedFillteredData = fillteredData as? [Chat] {
                    changedFillteredData.removeAll(where: { $0.isParent == false && $0.groupId == data.groupId })
                    self.fillteredData = changedFillteredData
                }
            } else {
                chats.removeAll(where: { $0.isParent == false && $0.groupId == data.groupId })
            }
        }
        tableView.reloadData()
    }
    
    func expandCollapseGroup(tableView: UITableView, indexPath: IndexPath) {
        let group: Group
        if isFiltering {
            if indexPath.row == 0 {
                group = fillteredData[indexPath.section] as! Group
            } else {
                group = (fillteredData[indexPath.section] as! Group).childs[indexPath.row - 1]
            }
        } else {
            if indexPath.row == 0 {
                group = groups[indexPath.section]
            } else {
                group = groups[indexPath.section].childs[indexPath.row - 1]
            }
        }
        if (checkOverrideAction(groupHolder: group)) {
            return;
        }
        group.isSelected = !group.isSelected
        if !group.isSelected{
            var sects = 0
            var sect = indexPath.section
            var id = group.id
            if let _ = groupMap[id] {
                var loooop = true
                repeat {
                    let c = sect + 1
                    if isFiltering {
                        if let o = self.fillteredData[c] as? Group {
                            if o.parent == id {
                                sects = sects + 1
                                sect = c
                                id = o.id
                                (self.fillteredData[c] as! Group).isSelected = false
                                self.groupMap.removeValue(forKey: (self.fillteredData[c] as! Group).id)
                            }
                            else {
                                loooop = false
                            }
                        }
                    }
                    else {
                        if c < self.groups.count && self.groups[c].parent == id {
                            sects = sects + 1
                            sect = c
                            id = self.groups[c].id
                            self.groups[c].isSelected = false
                            self.groupMap.removeValue(forKey: self.groups[c].id)
                        }
                        else {
                            loooop = false
                        }
                    }
                } while(loooop)
            }
            for i in stride(from: sects, to: 0, by: -1){
                if isFiltering {
                    self.fillteredData.remove(at: indexPath.section + i)
                }
                else {
                    self.groups.remove(at: indexPath.section + i)
                }
            }
            groupMap.removeValue(forKey: group.id)
        }
        if group.groupType == "NOTJOINED" {
            let alert = LibAlertController(title: "Do you want to join this group?".localized(), message: "Groups : \(group.name)\nMembers: \(group.by)".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Join".localized(), style: .default, handler: {(_) in
                self.joinOpenGroup(groupId: group.id, completion: { result in
                    if result {
                        DispatchQueue.main.async {
                            self.groupMap.removeAll()
                            let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                            editorGroupVC.hidesBottomBarWhenPushed = true
                            editorGroupVC.unique_l_pin = group.id
                            self.navigationController?.show(editorGroupVC, sender: nil)
                        }
                    }
                })
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        if group.childs.count == 0 {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    let idMe = User.getMyPin() as String?
                    if let cursorMember = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin from GROUPZ_MEMBER where group_id = '\(group.id)' and f_pin = '\(idMe!)'"), cursorMember.next() {
                        let groupId = group.chatId.isEmpty ? group.id : group.chatId
                        if let chooser = isChooser {
                            chooser("4", groupId)
                            dismiss(animated: true, completion: nil)
                            return
                        }
                        self.groupMap.removeAll()
                        let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                        editorGroupVC.hidesBottomBarWhenPushed = true
                        editorGroupVC.unique_l_pin = groupId
                        navigationController?.show(editorGroupVC, sender: nil)
                        cursorMember.close()
                    } else {
                        self.view.makeToast("You are not a member of this group".localized(), duration: 3)
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        } else {
            if indexPath.row == 0 {
                tableView.reloadData()
            } else {
                getGroups(id: group.id) { g in
                    DispatchQueue.main.async {
                        if self.isFiltering {
                            if self.fillteredData[indexPath.section] is Group {
                                self.groupMap[(self.fillteredData[indexPath.section] as! Group).id] = 1
                                self.fillteredData.insert(contentsOf: g, at: indexPath.section + 1)
                            }
                        } else {
                            self.groupMap[self.groups[indexPath.section].id] = 1
                            self.groups.insert(contentsOf: g, at: indexPath.section + 1)
                        }
                        tableView.reloadData()
                        
                        self.expandCollapseGroup(tableView: tableView, indexPath: IndexPath(row: 0, section: indexPath.section + 1))
                    }
                }
            }
        }
    }
    
    func pullGroupInfo(groupHolder: Group) {
        if groupHolder.isLounge {
            return
        }
        let groupId = groupHolder.chatId.isEmpty ? groupHolder.id : groupHolder.chatId
        let idMe = User.getMyPin() ?? ""
        DispatchQueue.global().async {
            _ = Nexilis.write(message: CoreMessage_TMessageBank.getRequestGroupWithoutMemberFromParent(fPin: idMe, groupId: groupId))
        }
    }
    
    func checkOverrideAction(groupHolder: Group) -> Bool {
        if groupHolder.isLounge {
            return false
        }
        let chatModifier = groupHolder.chatModifier
        if !chatModifier.isEmpty {
            if chatModifier == "cc" {
                APIS.openContactCenter();
            } else if chatModifier == "gpt" {
                APIS.openSmartChatbot();
            } else {
                APIS.openUrl(url: chatModifier)
            }
            return true
        }
//        switch (groupId){
//            case "18d1c6cffb70215af7b49" //bpkh konsultasi
//            , "18d1c6e37a20215af7b49"
//            , "18d1c6f852d0215af7b49"
//            , "18d1c6ff83a0215af7b49"
//            , "18d1c705e970215af7b49"
//            , "18d30db3bde0230d00c15" //ina konsultasi bot
//            , "18d30e64ce30230d00c15"
//            , "18d30e9b6d80230d00c15"
//            , "18d30ee00610230d00c15"
//            , "18d30f02f850230d00c15":
//                APIS.openSmartChatbot();
//                return true;
//            case "18d30daa4540230d00c15" //ina cc
//            , "18d30e59a950230d00c15"
//            , "18d30e9292b0230d00c15"
//            , "18d30ed8e250230d00c15"
//            , "18d30efa66c0230d00c15"
//            , "18d35b220540215af7b49" //bpkhcc
//            , "18d35b2f5ee0215af7b49"
//            , "18d35b356530215af7b49"
//            , "18d35b411510215af7b49"
//            , "18d35b46ae90215af7b49":
//                APIS.openContactCenter();
//                return true;
//            case "18d1c6d9f330215af7b49": //bpkh haji
//                APIS.openUrl(url: Utils.decrypt(str: "6]tov!l_opgn=hgz?ykmgv?yoro3kt?uo>yoro3kt??@yvzzn"))
//                return true;
//            case "18d1c6eefd40215af7b49": //bpkh bpjs
//                APIS.openUrl(url: Utils.decrypt(str: "1>ojq`g@tkqc.cbu:tfhbq:tjmjyfo:pj/tjmjyfo::;tquui"))
//                return true;
//            case "18d30e711c20230d00c15": //ina bpjs
//                APIS.openUrl(url: Utils.decrypt(str: "6]tov!l_ypvh=hgz?ykmgv?yoro3kt?sui>ykrgyomojrkyz??@yvzzn"))
//                return true;
//            case "18d30e47ae60230d00c15": //ina KTP, KK, SKL
//                APIS.openUrl(url: Utils.decrypt(str: "1>ojq`g@qul.cbu:tfhbq:tjmjyfo:npd/tfmbtjhjemftu::;tquui"))
//                return true;
//            case "18d30eb2e910230d00c15": //SIM, SKKB, SKBN
//                APIS.openUrl(url: Utils.decrypt(str: "4[rmt}j]qmw;fex=wiket=wmpm1ir=qsg<wipewmkmhpiwx==>wtxxl"))
//                return true;
//            case "18da1c0200f0215af7b49": //BPKH index BMI
//                APIS.openUrl(url: Utils.decrypt(str: "4[rmt}j]mqf}1ihrm=mqf=wmpm1ir=sm<wmpm1ir==>wtxxl"))
//                return true;
//            default:
//                break;
//        }
        return false
    }
    
}

extension ContactChatViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isFiltering {
            if ((segment.numberOfSegments == 3 && segment.selectedSegmentIndex == 2) || (segment.numberOfSegments < 3 && segment.selectedSegmentIndex == 1)) {
                return fillteredData.count
            }
            return 1
        } else {
            if ((segment.numberOfSegments == 3 && segment.selectedSegmentIndex == 2) || (segment.numberOfSegments < 3 && segment.selectedSegmentIndex == 1)) {
                return groups.count
            }
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var value = 0
        if isFiltering {
            func filterGroup(groups: [Group]) {
                let group = groups[section]
                if group.isSelected {
                    if let _ = groupMap[group.id] {
                        value = 1
                    }
                    else {
                        value = group.childs.count + 1
                    }
                } else {
                    value = 1
                }
            }
            if ((segment.numberOfSegments == 3 && segment.selectedSegmentIndex == 2) || (segment.numberOfSegments < 3 && segment.selectedSegmentIndex == 1)), let groups = fillteredData as? [Group] {
                filterGroup(groups: groups)
            } else {
                value = fillteredData.count
            }
            return value
        }
        if segment.numberOfSegments == 3 {
            switch segment.selectedSegmentIndex {
            case 0:
                value = chats.count
            case 1:
                value = contacts.count
            case 2:
                let group = groups[section]
                if group.isSelected {
                    if let _ = groupMap[group.id] {
                        value = 1
                    }
                    else {
                        value = group.childs.count + 1
                    }
                } else {
                    value = 1
                }
            default:
                value = chats.count
            }
        } else {
            switch segment.selectedSegmentIndex {
            case 0:
                value = contacts.count
            case 1:
                let group = groups[section]
                if group.isSelected {
                    if let _ = groupMap[group.id] {
                        value = 1
                    }
                    else {
                        value = group.childs.count + 1
                    }
                } else {
                    value = 1
                }
            default:
                value = chats.count
            }
        }
        if value == 0 {
            noData = true
            value = 1
            tableView.separatorStyle = .none
        } else {
            noData = false
            tableView.separatorStyle = .singleLine
        }
        return value
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if segment.numberOfSegments != 3 || (segment.numberOfSegments == 3 && segment.selectedSegmentIndex != 0) {
            return nil
        }
        let data: Chat
        if isFiltering {
            if fillteredData.count == 0 {
                return nil
            }
            data = fillteredData[indexPath.row] as! Chat
        } else {
            if chats.count == 0 {
                return nil
            }
            data = chats[indexPath.row]
        }
        if !data.isParent && segment.selectedSegmentIndex == 0 {
            if self.archivedChats.count > 0 && indexPath.row == 0 {
                return nil
            }
            let archiveAction = UIContextualAction(style: .normal, title: nil) { (_, _, completionHandler) in
                DispatchQueue.global().async {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                                "pinned" : 0,
                                "archived" : Date().currentTimeMillis()
                            ], _where: "l_pin = '\(data.pin)'")
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                }
                self.chats.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .right)
                self.getChats() {
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.isGettingData = false
                    }
                }
                completionHandler(true)
            }
            archiveAction.backgroundColor = .mainColor
            let archiveIcon = UIImage(systemName: "archivebox.fill")!.createCustomIconWithText(text: "Archive".localized())
            archiveAction.image = archiveIcon

            var textPinned = "Pin".localized()
            var pinnedDate = Date().currentTimeMillis()
            var imagePinned = UIImage(systemName: "pin.fill")!
            if data.pinned != 0 && !data.isFolPinned {
                textPinned = "Unpin".localized()
                pinnedDate = 0
                imagePinned = UIImage(systemName: "pin.slash.fill")!
            }
            let unpinAction = UIContextualAction(style: .normal, title: textPinned) { (_, _, completionHandler) in
                if pinnedDate != 0 && ((self.listMaxArchived[data.groupId] != nil && self.listMaxArchived[data.groupId]!.count == 3) || (self.listMaxArchived.count == 3)) {
                    let alertController = LibAlertController(
                        title: "You can only pin 3 chats".localized(),
                        message: nil,
                        preferredStyle: .alert
                    )
                    
                    alertController.addAction(UIAlertAction(title: "OK".localized(), style: .cancel, handler: nil))
                    
                    if UIApplication.shared.visibleViewController?.navigationController != nil {
                        UIApplication.shared.visibleViewController?.navigationController?.present(alertController, animated: true, completion: nil)
                    } else {
                        UIApplication.shared.visibleViewController?.present(alertController, animated: true, completion: nil)
                    }
                } else {
                    DispatchQueue.global().async {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                                    "pinned" : pinnedDate
                                ], _where: "l_pin = '\(data.pin)'")
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                    }
                    self.chats.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .right)
                    self.getChats() {
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            self.isGettingData = false
                        }
                    }
                }
                completionHandler(true)
            }
            unpinAction.backgroundColor = .darkGray
            let pinIcon = imagePinned.rotateImage(byDegrees: 45).createCustomIconWithText(text: textPinned, color: .white)
            unpinAction.image = pinIcon

            let configuration = UISwipeActionsConfiguration(actions: [archiveAction, unpinAction])
            return configuration
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        switch segment.selectedSegmentIndex {
        case 0:
            if segment.numberOfSegments < 3 {
                cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifierContact", for: indexPath)
                let content = cell.contentView
                if content.subviews.count > 0 {
                    content.subviews.forEach { $0.removeFromSuperview() }
                }
                let data: User
                if isFiltering {
                    data = fillteredData[indexPath.row] as! User
                } else {
                    if  indexPath.row > contacts.count - 1 {
                        return cell
                    }
                    data = contacts[indexPath.row]
                }
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40.0, height: 40.0))
                content.addSubview(imageView)
                imageView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20.0),
                    imageView.centerYAnchor.constraint(equalTo: content.centerYAnchor),
                    imageView.widthAnchor.constraint(equalToConstant: 40.0),
                    imageView.heightAnchor.constraint(equalToConstant: 40.0)
                ])
                if data.pin == "-997" {
                    imageView.circle()
                    if let urlGif = Bundle.resourceBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif") {//resourcesMediaBundle
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
                }
                else {
                    getImage(name: data.thumb, placeholderImage: UIImage(named: "Profile---Black", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                        imageView.image = image
                    })
                }
                let titleView = UILabel()
                content.addSubview(titleView)
                titleView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    titleView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 15.0),
                    titleView.centerYAnchor.constraint(equalTo: content.centerYAnchor)
                ])
                titleView.font = UIFont.systemFont(ofSize: 14 + String.offset())
                if (User.isOfficial(official_account: data.official ?? "") || User.isOfficialRegular(official_account: data.official ?? "")) && data.pin != "-997" {
                    titleView.attributedText = self.set(image: UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4, colorText: UIColor.officialColor)

                } else if User.isVerified(official_account: data.official ?? "") {
                    titleView.attributedText = self.set(image: UIImage(named: "ic_verified", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4, colorText: UIColor.verifiedColor)
                }
                else if User.isInternal(userType: data.userType ?? "") {
                    titleView.attributedText = self.set(image: UIImage(named: "ic_internal", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4, colorText: UIColor.internalColor)
                } else if User.isCallCenter(userType: data.userType ?? "") {
                    titleView.attributedText = self.set(image: UIImage(named: "pb_call_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4, colorText: UIColor.ccColor)
                } else {
                    titleView.text = data.fullName
                }
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifierChat", for: indexPath)
                let content = cell.contentView
                if content.subviews.count > 0 {
                    content.subviews.forEach { $0.removeFromSuperview() }
                }
                if noData {
                    let labelNochat = UILabel()
                    labelNochat.text = "There are no conversations".localized()
                    labelNochat.font = .systemFont(ofSize: 13 + String.offset())
                    labelNochat.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
                    content.addSubview(labelNochat)
                    labelNochat.anchor(centerX: content.centerXAnchor, centerY: content.centerYAnchor)
                    cell.backgroundColor = .clear
                    cell.selectionStyle = .none
                    return cell
                }
                var data: Chat
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
                if self.archivedChats.count > 0 && indexPath.row == 0 {
                    let imageView = UIImageView()
                    content.addSubview(imageView)
                    imageView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        imageView.centerYAnchor.constraint(equalTo: content.centerYAnchor),
                        imageView.widthAnchor.constraint(equalToConstant: 20.0),
                        imageView.heightAnchor.constraint(equalToConstant: 20.0),
                        imageView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 25.0)
                    ])
                    imageView.image = UIImage(systemName: "archivebox")!
                    imageView.tintColor = .darkGray
                    
                    let titleView = UILabel()
                    content.addSubview(titleView)
                    titleView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        titleView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 25.0),
                        titleView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -40.0),
                        titleView.centerYAnchor.constraint(equalTo: content.centerYAnchor),
                    ])
                    titleView.font = UIFont.boldSystemFont(ofSize: 14 + String.offset())
                    titleView.text = "Archived".localized()
                    titleView.textColor = .darkGray
                    cell.backgroundColor = .clear
                    cell.separatorInset = UIEdgeInsets(top: 0, left: 60.0, bottom: 0, right: 0)
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
                            getImage(name: data.profile, placeholderImage: UIImage(named: data.pin == "-999" ? "pb_button" : (data.messageScope == MessageScope.WHISPER || data.messageScope == MessageScope.CALL || data.messageScope == MessageScope.MISSED_CALL) ? "Profile---Black" : "group-chat", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
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
                let viewPinned = UIImageView()
                
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
                
                if data.pinned != 0 && !data.isFolPinned {
                    viewPinned.image = UIImage(systemName: "pin.fill")!.rotateImage(byDegrees: 45).withRenderingMode(.alwaysTemplate)
                    viewPinned.tintColor = .darkGray
                    content.addSubview(viewPinned)
                    viewPinned.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        viewPinned.widthAnchor.constraint(equalToConstant: 18),
                        viewPinned.heightAnchor.constraint(equalToConstant: 18)
                    ])
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
                                if data.messageScope != MessageScope.CALL && data.messageScope != MessageScope.MISSED_CALL && !data.messageId.contains("NTFPIN_") && data.messageScope != MessageScope.GPT_CHATBOT {
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
                            if data.messageScope == MessageScope.WHISPER && data.isBot == 1 {
                                stringMessage.append(NSAttributedString(string: Utils.getGPTBotName() + ": ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12 + String.offset(), weight: .medium)]))
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
                    if data.pinned != 0 && !data.isFolPinned {
                        NSLayoutConstraint.activate([
                            viewPinned.topAnchor.constraint(equalTo: timeView.bottomAnchor, constant: 5.0)
                        ])
                        if data.counter == "0" {
                            NSLayoutConstraint.activate([
                                viewPinned.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20)
                            ])
                        } else {
                            NSLayoutConstraint.activate([
                                viewPinned.trailingAnchor.constraint(equalTo: viewCounter.leadingAnchor, constant: -5)
                            ])
                        }
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
                    if data.pinned != 0 && !data.isFolPinned {
                        NSLayoutConstraint.activate([
                            viewPinned.centerYAnchor.constraint(equalTo: content.centerYAnchor)
                        ])
                        if data.counter == "0" {
                            NSLayoutConstraint.activate([
                                viewPinned.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -5)
                            ])
                        } else {
                            NSLayoutConstraint.activate([
                                viewPinned.trailingAnchor.constraint(equalTo: viewCounter.leadingAnchor, constant: -5)
                            ])
                        }
                    }
                }
            }
        case 1:
            if segment.numberOfSegments < 3 {
                cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifierGroup", for: indexPath)
                var content = cell.defaultContentConfiguration()
                content.textProperties.font = UIFont.systemFont(ofSize: 14 + String.offset())
                let group: Group
                if isFiltering {
                    if indexPath.row == 0 {
                        group = fillteredData[indexPath.section] as! Group
                    } else {
                        if (fillteredData[indexPath.section] as! Group).childs.count > 0 {
                            group = (fillteredData[indexPath.section] as! Group).childs[indexPath.row - 1]
                        } else {
                            return cell
                        }
                    }
                } else {
                    if indexPath.row == 0 {
                        if indexPath.section > (groups.count - 1) {
                            return cell
                        }
                        group = groups[indexPath.section]
                    } else {
                        group = groups[indexPath.section].childs[indexPath.row - 1]
                    }
                }
                if group.official == "1" && group.parent == "" {
                    content.attributedText = self.set(image: UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(group.name)", size: 15, y: -4, colorText: self.traitCollection.userInterfaceStyle == .dark ? .white : .black)
                }
                else if group.isOpen == "1" && group.parent == "" {
                    if self.traitCollection.userInterfaceStyle == .dark {
                        content.attributedText = self.set(image: UIImage(systemName: "globe")!.withTintColor(.white), with: "  \(group.name)", size: 15, y: -4, colorText: self.traitCollection.userInterfaceStyle == .dark ? .white : .black)
                    } else {
                        content.attributedText = self.set(image: UIImage(systemName: "globe")!, with: "  \(group.name)", size: 15, y: -4)
                    }
                } else if group.parent == "" {
                    if self.traitCollection.userInterfaceStyle == .dark {
                        content.attributedText = self.set(image: UIImage(systemName: "lock.fill")!.withTintColor(.white), with: "  \(group.name)", size: 15, y: -4, colorText: self.traitCollection.userInterfaceStyle == .dark ? .white : .black)
                    } else {
                        content.attributedText = self.set(image: UIImage(systemName: "lock.fill")!, with: "  \(group.name)", size: 15, y: -4, colorText: self.traitCollection.userInterfaceStyle == .dark ? .white : .black)
                    }
                } else {
                    content.text = group.name
                }
                if group.childs.count > 0 {
                    if group.chatModifier.isEmpty {
                        let iconName = (group.isSelected) ? "chevron.up.circle" : "chevron.down.circle"
                        let imageView = UIImageView(image: UIImage(systemName: iconName))
                        imageView.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
                        cell.accessoryView = imageView
                    } else {
                        cell.accessoryView = nil
                        cell.accessoryType = .none
                    }
                    getImage(name: group.profile, placeholderImage: UIImage(named: "group-chat", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                        content.image = image
                    }
                }
                else {
                    cell.accessoryView = nil
                    cell.accessoryType = .none
                    if group.isOpen == "1" && group.parent == "" {
                        getImage(name: group.profile, placeholderImage: UIImage(named: "group-chat", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                            content.image = image
                        }
                    } else {
                        getImage(name: group.profile, placeholderImage: UIImage(named: "Conversation---Black", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                            content.image = image
                        }
                    }
                }
                content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
                cell.contentConfiguration = content
                if !group.level.isEmpty {
                    if group.level != "-1" && Int(group.level)! < 7 {
                        cell.contentView.layoutMargins = .init(top: 0.0, left: CGFloat(25 * Int(group.level)!), bottom: 0.0, right: 0)
                    } else if Int(group.level)! > 6 {
                        cell.contentView.layoutMargins = .init(top: 0.0, left: CGFloat(25 * (Int(group.level)! - 6)), bottom: 0.0, right: 0)
                    }
                }
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifierContact", for: indexPath)
                let content = cell.contentView
                if content.subviews.count > 0 {
                    content.subviews.forEach { $0.removeFromSuperview() }
                }
                let data: User
                if isFiltering {
                    data = fillteredData[indexPath.row] as! User
                } else {
                    if  indexPath.row > contacts.count - 1 {
                        return cell
                    }
                    data = contacts[indexPath.row]
                }
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40.0, height: 40.0))
                content.addSubview(imageView)
                imageView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20.0),
                    imageView.centerYAnchor.constraint(equalTo: content.centerYAnchor),
                    imageView.widthAnchor.constraint(equalToConstant: 40.0),
                    imageView.heightAnchor.constraint(equalToConstant: 40.0)
                ])
                if data.pin == "-997" {
                    imageView.circle()
                    if let urlGif = Bundle.resourceBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif") {//resourcesMediaBundle
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
                }
                else {
                    getImage(name: data.thumb, placeholderImage: UIImage(named: "Profile---Black", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                        imageView.image = image
                    })
                }
                let titleView = UILabel()
                content.addSubview(titleView)
                titleView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    titleView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 15.0),
                    titleView.centerYAnchor.constraint(equalTo: content.centerYAnchor)
                ])
                titleView.font = UIFont.systemFont(ofSize: 14 + String.offset())
                if (User.isOfficial(official_account: data.official ?? "") || User.isOfficialRegular(official_account: data.official ?? "")) && data.pin != "-997" {
                    titleView.attributedText = self.set(image: UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4, colorText: UIColor.officialColor)

                } else if User.isVerified(official_account: data.official ?? "") {
                    titleView.attributedText = self.set(image: UIImage(named: "ic_verified", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4, colorText: UIColor.verifiedColor)
                }
                else if User.isInternal(userType: data.userType ?? "") {
                    titleView.attributedText = self.set(image: UIImage(named: "ic_internal", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4, colorText: UIColor.internalColor)
                } else if User.isCallCenter(userType: data.userType ?? "") {
                    titleView.attributedText = self.set(image: UIImage(named: "pb_call_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4, colorText: UIColor.ccColor)
                } else {
                    titleView.text = data.fullName
                }
            }
        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifierGroup", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.textProperties.font = UIFont.systemFont(ofSize: 14 + String.offset())
            let group: Group
            if isFiltering {
                if indexPath.row == 0 {
                    group = fillteredData[indexPath.section] as! Group
                } else {
                    if (fillteredData[indexPath.section] as! Group).childs.count > 0 {
                        group = (fillteredData[indexPath.section] as! Group).childs[indexPath.row - 1]
                    } else {
                        return cell
                    }
                }
            } else {
                if indexPath.row == 0 {
                    if indexPath.section > (groups.count - 1) {
                        return cell
                    }
                    group = groups[indexPath.section]
                } else {
                    group = groups[indexPath.section].childs[indexPath.row - 1]
                }
            }
            if group.official == "1" && group.parent == "" {
                content.attributedText = self.set(image: UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(group.name)", size: 15, y: -4, colorText: self.traitCollection.userInterfaceStyle == .dark ? .white : .black)
            }
            else if group.isOpen == "1" && group.parent == "" {
                if self.traitCollection.userInterfaceStyle == .dark {
                    content.attributedText = self.set(image: UIImage(systemName: "globe")!.withTintColor(.white), with: "  \(group.name)", size: 15, y: -4, colorText: self.traitCollection.userInterfaceStyle == .dark ? .white : .black)
                } else {
                    content.attributedText = self.set(image: UIImage(systemName: "globe")!, with: "  \(group.name)", size: 15, y: -4, colorText: self.traitCollection.userInterfaceStyle == .dark ? .white : .black)
                }
            } else if group.parent == "" {
                if self.traitCollection.userInterfaceStyle == .dark {
                    content.attributedText = self.set(image: UIImage(systemName: "lock.fill")!.withTintColor(.white), with: "  \(group.name)", size: 15, y: -4, colorText: self.traitCollection.userInterfaceStyle == .dark ? .white : .black)
                } else {
                    content.attributedText = self.set(image: UIImage(systemName: "lock.fill")!, with: "  \(group.name)", size: 15, y: -4, colorText: self.traitCollection.userInterfaceStyle == .dark ? .white : .black)
                }
            } else {
                content.text = group.name
            }
            if group.childs.count > 0 {
                let iconName = (group.isSelected) ? "chevron.up.circle" : "chevron.down.circle"
                let imageView = UIImageView(image: UIImage(systemName: iconName))
                imageView.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
                cell.accessoryView = imageView
                getImage(name: group.profile, placeholderImage: UIImage(named: "group-chat", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                    content.image = image
                }
            }
            else {
                cell.accessoryView = nil
                cell.accessoryType = .none
                if group.isOpen == "1" && group.parent == "" {
                    getImage(name: group.profile, placeholderImage: UIImage(named: "group-chat", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                        content.image = image
                    }
                } else {
                    getImage(name: group.profile, placeholderImage: UIImage(named: "Conversation---Black", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                        content.image = image
                    }
                }
            }
            content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
            cell.contentConfiguration = content
            if !group.level.isEmpty {
                if group.level != "-1" && Int(group.level)! < 7 {
                    cell.contentView.layoutMargins = .init(top: 0.0, left: CGFloat(25 * Int(group.level)!), bottom: 0.0, right: 0)
                } else if Int(group.level)! > 6 {
                    cell.contentView.layoutMargins = .init(top: 0.0, left: CGFloat(25 * (Int(group.level)! - 6)), bottom: 0.0, right: 0)
                }
            }
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifierContact", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = ""
            cell.contentConfiguration = content
        }
        cell.backgroundColor = .clear
        cell.separatorInset = UIEdgeInsets(top: 0, left: 60.0, bottom: 0, right: 0)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let fontSize = Int(SecureUserDefaults.shared.value(forKey: "font_size") ?? "0")
        var finalHeight = 75.0
        if self.archivedChats.count > 0 && indexPath.row == 0 {
            finalHeight = 50.0
        }
        if fontSize == 4 {
            finalHeight += 10
        } else if fontSize == 6 {
            finalHeight += 20
        }
        return finalHeight
    }
    
    private func getRealStatus(messageId: String) -> String {
        var status = "1"
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorStatus = Database.shared.getRecords(fmdb: fmdb, query: "SELECT status, f_pin FROM MESSAGE_STATUS WHERE message_id='\(messageId)'") {
                    var listStatus: [Int] = []
                    while cursorStatus.next() {
                        listStatus.append(Int(cursorStatus.string(forColumnIndex: 0)!)!)
                    }
                    cursorStatus.close()
                    status = "\(listStatus.min() ?? 2)"
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        return status
    }
    
}


extension ContactChatViewController: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func set(image: UIImage, with text: String, size: CGFloat, y: CGFloat, colorText: UIColor = UIColor.black) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: y, width: size, height: size)
        let attachmentStr = NSAttributedString(attachment: attachment)
        
        let mutableAttributedString = NSMutableAttributedString()
        mutableAttributedString.append(attachmentStr)
        
        let attributedStringColor = [NSAttributedString.Key.foregroundColor : colorText]
        let textString = NSAttributedString(string: text, attributes: attributedStringColor)
        mutableAttributedString.append(textString)
        
        
        return mutableAttributedString
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
        if let cBtn = searchBar.value(forKey: "cancelButton") as? UIButton {
            cBtn.setTitle("Cancel".localized(), for: .normal)
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }
    
}
