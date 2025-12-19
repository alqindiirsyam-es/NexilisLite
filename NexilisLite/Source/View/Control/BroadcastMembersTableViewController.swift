//
//  BroadcastMembersTableViewController.swift
//  Qmera
//
//  Created by Kevin Maulana on 06/10/21.
//

import UIKit
import FMDB

class BroadcastMembersTableViewController: UITableViewController, UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    
    var contacts: [User] = []
    
    var groups: [Group] = []
    
    var existing : [String] = []
    
    var isGroup = false
    
    var searchController: UISearchController!
    
    var fillteredData: [Any] = []
    
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isFilltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
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
    
    func filterContentForSearchText(_ searchText: String) {
        if(isGroup){
            if(searchText.isEmpty){
                fillteredData = groups
            }
            else {
                fillteredData = self.groups.filter { $0.name.lowercased().contains(searchText.lowercased()) }
            }
        }
        else {
            if(searchText.isEmpty){
                fillteredData = contacts
            }
            else {
                fillteredData = self.contacts.filter { $0.fullName.lowercased().contains(searchText.lowercased()) }
            }

        }
        tableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .normal)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "Search".localized(), attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)])
//        searchController.searchBar.updateHeight(height: 36, radius: 18)
//        searchController.searchBar.setMagnifyingGlassColorTo(color: .white)
        searchController.searchBar.setImage(UIImage(), for: .search, state: .normal)
        searchController.searchBar.setPositionAdjustment(UIOffset(horizontal: 10, vertical: 0), for: .search)
        if #unavailable(iOS 26.0) {
            searchController.searchBar.setCustomBackgroundImage(image: UIImage(named: self.traitCollection.userInterfaceStyle == .dark ? "nx_search_bar_dark" : "nx_search_bar", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        }
        searchController.searchBar.tintColor = .mainColor
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        let buttonAddFriend = UIBarButtonItem(image: UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), style: .plain, target: self, action: #selector(addFriend(sender:)))
        navigationItem.rightBarButtonItem = buttonAddFriend
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.getData()
        })
    }
    
    @objc func addFriend(sender: UIBarButtonItem) {
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "addFriendNav") as! UINavigationController
        Utils.addBackground(view: controller.view)
        if let vc = controller.viewControllers.first as? AddFriendTableViewController {
            vc.isDismiss = {
                self.contacts.removeAll()
                self.getContacts {
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
        self.navigationController?.present(controller, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        pullBuddy()
    }
    
    @objc func onReload(notification: NSNotification) {
        getData()
    }

    // MARK: - Table view data source
    
    func getData() {
        contacts.removeAll()
        groups.removeAll()
        getContacts {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        getGroups { g in
            self.groups.append(contentsOf: g)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private func getContacts(completion: @escaping ()->()) {
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
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
                            if(!self.existing.contains(user.pin)){
                                self.contacts.append(user)
                            }
                        }
                        cursorData.close()
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
                completion()
            })
        }
    }
    
    private func getGroupRecursive(fmdb: FMDatabase, id: String = "", parent: String = "") -> [Group] {
        var data: [Group] = []
        var query = "select g.group_id, g.f_name, g.image_id, g.quote, g.created_by, g.created_date, g.parent, g.group_type, g.is_open, g.official, g.is_education from GROUPZ g where "
        if id.isEmpty {
            query += "g.parent = '\(parent)'"
        } else {
            query += "g.group_id = '\(id)'"
        }
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
                    isEducation: cursor.string(forColumnIndex: 10) ?? "")
                
//                if group.chatId.isEmpty {
//                    let lounge = Group(id: group.id, name: "Lounge".localized(), profile: "", quote: group.quote, by: group.by, date: group.date, parent: group.id, chatId: group.chatId, groupType: group.groupType, isOpen: group.isOpen, official: group.official, isEducation: group.isEducation, isLounge: true)
//                    group.childs.append(lounge)
//                }
//                
//                if let topicCursor = Database.shared.getRecords(fmdb: fmdb, query: "select chat_id, title, thumb from DISCUSSION_FORUM where group_id = '\(group.id)'") {
//                    while topicCursor.next() {
//                        let topic = Group(id: group.id,
//                                          name: topicCursor.string(forColumnIndex: 1) ?? "",
//                                          profile: topicCursor.string(forColumnIndex: 2) ?? "",
//                                          quote: group.quote,
//                                          by: group.by,
//                                          date: group.date,
//                                          parent: group.id,
//                                          chatId: topicCursor.string(forColumnIndex: 0) ?? "",
//                                          groupType: group.groupType,
//                                          isOpen: group.isOpen,
//                                          official: group.official,
//                                          isEducation: group.isEducation)
//                        group.childs.append(topic)
//                    }
//                    topicCursor.close()
//                }
//                
//                if !group.id.isEmpty {
//                    if group.official == "1" {
//                        let idMe = User.getMyPin() as String?
//                        if let cursorUser = Database.shared.getRecords(fmdb: fmdb, query: "SELECT user_type FROM BUDDY where f_pin='\(idMe!)'"), cursorUser.next() {
//                            if cursorUser.string(forColumnIndex: 0) == "23" || cursorUser.string(forColumnIndex: 0) == "24" {
//                                group.childs.append(contentsOf: getGroupRecursive(fmdb: fmdb, parent: group.id))
//                            }
//                            cursorUser.close()
//                        }
//                    } else if group.official != "1"{
//                        group.childs.append(contentsOf: getGroupRecursive(fmdb: fmdb, parent: group.id))
//                    }
//                }
                if(!self.existing.contains(group.id)){
                    data.append(group)
                }
            }
            cursor.close()
        }
        return data
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if(isGroup){
            if(isFilltering){
                return fillteredData.count
            }
            return groups.count
        }
        else {
            if(isFilltering){
                return fillteredData.count
            }
            return contacts.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if(isGroup) {
            cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifierGroup", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.textProperties.font = UIFont.systemFont(ofSize: 14)
            let group: Group
            if isFilltering {
                group = fillteredData[indexPath.row] as! Group
            } else {
                group = groups[indexPath.row]
            }
            content.text = group.name
            content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
            getImage(name: group.profile, placeholderImage: UIImage(named: "group-chat", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                content.image = image
            }
            cell.contentConfiguration = content
            cell.tag = indexPath.row
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifierContact", for: indexPath)
            var content = cell.defaultContentConfiguration()
            let data: User
            if isFilltering {
                data = fillteredData[indexPath.row] as! User
            } else {
                data = contacts[indexPath.row]
            }
            content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
            getImage(name: data.thumb, placeholderImage: UIImage(named: "Profile---Black", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                content.image = image
            })
            if User.isOfficial(official_account: data.official ?? "") || User.isOfficialRegular(official_account: data.official ?? "") {
                content.attributedText = self.set(image: UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4, colorText: UIColor.officialColor)
                
            } else if User.isVerified(official_account: data.official ?? "") {
                content.attributedText = self.set(image: UIImage(named: "ic_verified", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4, colorText: UIColor.verifiedColor)
            }
            else if User.isInternal(userType: data.userType ?? "") {
                content.attributedText = self.set(image: UIImage(named: "ic_internal", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4, colorText: UIColor.internalColor)
            } else if User.isCallCenter(userType: data.userType ?? "") {
//                let dataCategory = CategoryCC.getDataFromServiceId(service_id: data.ex_offmp!)
//                if dataCategory != nil {
//                    content.attributedText = self.set(image: UIImage(named: "pb_call_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName) (\(dataCategory!.service_name))", size: 15, y: -4, colorText: UIColor.ccColor)
//                } else {
                    content.attributedText = self.set(image: UIImage(named: "pb_call_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(data.fullName)", size: 15, y: -4, colorText: UIColor.ccColor)
//                }
            } else {
                content.text = data.fullName
            }
            content.textProperties.font = UIFont.systemFont(ofSize: 14)
            cell.contentConfiguration = content
            cell.tag = indexPath.row
        }
        return cell
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cell = sender as! UITableViewCell
        if let destination = segue.destination as? BroadcastViewController {
            if(isGroup){
                if(isFilltering){
                    destination.groups.append(fillteredData[cell.tag] as! Group)
                }
                else {
                    destination.groups.append(groups[cell.tag])
                }
            }
            else {
                if(isFilltering){
                    destination.contacts.append(fillteredData[cell.tag] as! User)
                }
                else {
                    destination.contacts.append(contacts[cell.tag])
                }
            }
            //print("GROUPS \(destination.groups)")
            //print("CONTACTS \(destination.contacts)")
            destination.memberTable.reloadData()
            destination.tableView.reloadData()
        }
    }
}
