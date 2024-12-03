//
//  GroupMemberViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 30/09/21.
//

import UIKit

class GroupMemberViewController: UITableViewController {
    
    private var searchController: UISearchController!
    
    var group: Group!
    
    var isDismiss: (() -> ())?
    
    var isContactCenterInvite = false
    
    private var availableUser: [User] = []
    
    private var fillteredUser: [User] = []
    
    private var isSearchBarEmpty: Bool {
        return searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var isFilltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    private var userSelected: [User] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add New Member(s)".localized()
        
        navigationController?.navigationBar.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add(sender:)))
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.tintColor = .white
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.updateHeight(height: 36, radius: 18)
        searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "Search".localized(), attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)])
        
        definesPresentationContext = true
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        
        getData { users in
            self.availableUser.append(contentsOf: users)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    @objc func add(sender: Any) {
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ fmdb, rollback in
                do {
                    var result: Int = 0
                    for u in self.userSelected {
                        if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getAddGroupMember(p_group_id: self.group.id, p_member_pin: u.pin, p_position: "0")), response.isOk() {
                            let arrayChatId = self.group.topics.filter({ t in
                                return t.title != "Lounge".localized()
                            }).map { t in
                                return t.chatId
                            }.joined(separator: ",")
                            if let responseTopic = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getAddChatMember(groupId: self.group.id, chatId: arrayChatId, pin: u.pin)), responseTopic.isOk() {
                                let insert = try! Database.shared.insertRecord(fmdb: fmdb, table: "GROUPZ_MEMBER", cvalues: [
                                    "group_id": self.group.id,
                                    "f_pin": u.pin,
                                    "position": "0", // 0: member, 1: Admin
                                    "user_id": u.pin,
                                    "first_name": u.firstName,
                                    "last_name": u.lastName,
                                    "msisdn": "",
                                    "thumb_id": u.thumb,
                                    "created_date": Date().currentTimeMillis()
                                ], replace: true)
                                if insert > 0 {
                                    if self.group.isInternal {
                                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: ["user_type": "23"], _where: "f_pin = '\(u.pin)'")
                                    }
                                }
                                result += 1
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        if self.userSelected.count == result {
                            self.navigationController?.dismiss(animated: true, completion: {
                                self.isDismiss?()
                            })
                        } else {
                            self.showToast(message: "Server busy".localized(), seconds: 3)
                        }
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        }
    }
    
    // MARK: - Data source
    
    func getData(completion: @escaping ([User]) -> ()) {
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    var r: [User] = []
                    var query =  "SELECT f_pin, first_name, last_name, image_id, user_type FROM BUDDY where f_pin not in (select m.f_pin from GROUPZ_MEMBER m where m.group_id = '\(self.group.id)') and official_account = '0' order by 2 collate nocase asc"
                    if self.isContactCenterInvite {
                        query =  "SELECT f_pin, first_name, last_name, image_id, user_type FROM BUDDY where f_pin not in (select m.f_pin from GROUPZ_MEMBER m where m.group_id = '\(self.group.id)') and user_type = '23' and official_account = '0' order by 2 collate nocase asc"
                    }
                    if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                        while cursorData.next() {
                            let user = User(pin: cursorData.string(forColumnIndex: 0) ?? "",
                                                firstName: cursorData.string(forColumnIndex: 1) ?? "",
                                                lastName: cursorData.string(forColumnIndex: 2) ?? "",
                                                thumb: cursorData.string(forColumnIndex: 3) ?? "")
                            user.userType = cursorData.string(forColumnIndex: 4)
                            if (user.firstName + " " + user.lastName).trimmingCharacters(in: .whitespaces) == "USR\(user.pin)" {
                                continue
                            }
                            r.append(user)
                        }
                        cursorData.close()
                    }
                    completion(r)
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        }
    }
    
    func filterContentForSearchText(_ searchText: String) {
        fillteredUser = availableUser.filter({ d in
            let name = "\(d.firstName) \(d.lastName)".trimmingCharacters(in: .whitespaces)
            return name.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user: User
        if isFilltering {
            user = fillteredUser[indexPath.row]
        } else {
            user = availableUser[indexPath.row]
        }
        user.isSelected = !user.isSelected
        tableView.reloadData()
        if user.isSelected {
            userSelected.append(user)
        } else {
            if let index = userSelected.firstIndex(of: user) {
                userSelected.remove(at: index)
            }
        }
        if userSelected.count == 1 {
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else if userSelected.count == 0 {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFilltering {
            return fillteredUser.count
        }
        return availableUser.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let user: User
        if isFilltering {
            user = fillteredUser[indexPath.row]
        } else {
            user = availableUser[indexPath.row]
        }
        content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
        getImage(name: user.thumb, placeholderImage: UIImage(named: "Profile---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
            content.image = image
            if !result {
                content.imageProperties.tintColor = .mainColor
            }
        }
        if user.userType == "23" {
            content.attributedText = self.set(image: UIImage(named: "ic_internal", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: " " + (user.firstName + " " + user.lastName).trimmingCharacters(in: .whitespaces), size: 15, y: -4)
        } else if user.userType == "24" {
            content.attributedText = self.set(image: UIImage(named: "pb_call_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: " " + (user.firstName + " " + user.lastName).trimmingCharacters(in: .whitespaces), size: 15, y: -4)
        } else {
            content.text = (user.firstName + " " + user.lastName).trimmingCharacters(in: .whitespaces)
        }
        cell.contentConfiguration = content
        cell.accessoryType = user.isSelected ? .checkmark : .none
        return cell
    }

}

extension GroupMemberViewController: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
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
    
}
