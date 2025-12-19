//
//  QmeraCallContactViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 12/10/21.
//

import UIKit

class QmeraCallContactViewController: UITableViewController {
    
    private let searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.autocapitalizationType = .none
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.updateHeight(height: 36, radius: 18)
        searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "Search chats & messages".localized(), attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)])
        return searchController
    }()
    
    private var users: [User] = []
    
    private var fillteredUser: [User] = []
    
    private var isSearchBarEmpty: Bool {
        return searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var isFilltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    var isDismiss: ((User) -> ())?
    
    var selectedUser: [User] = []
    
    var isInviteCC = false
    
    var listFriends = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Friends".localized()
        
        if !isInviteCC {
            navigationController?.navigationBar.prefersLargeTitles = true
        } else {
            let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
            navigationController?.navigationBar.titleTextAttributes = textAttributes
            navigationController?.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
        }
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        
        definesPresentationContext = true
        
        if !listFriends {
            let buttonAddFriend = UIBarButtonItem(image: UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), style: .plain, target: self, action: #selector(addFriend(sender:)))
            navigationItem.rightBarButtonItem = buttonAddFriend
        }
        
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        
        getContacts { users in
            self.users.append(contentsOf: users)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
    }
    
    @objc func addFriend(sender: UIBarButtonItem) {
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "addFriendNav") as! UINavigationController
        Utils.addBackground(view: controller.view)
        if let vc = controller.viewControllers.first as? AddFriendTableViewController {
            vc.isDismiss = {
                self.users.removeAll()
                self.getContacts { users in
                    self.users.append(contentsOf: users)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
        self.navigationController?.present(controller, animated: true, completion: nil)
    }
    
    private func getContacts(completion: @escaping ([User]) -> ()) {
        var contacts: [User] = []
        DispatchQueue.global().async {
            var query = "SELECT f_pin, first_name, last_name, image_id, user_type, official_account, ex_offmp FROM BUDDY where f_pin <> '\(User.getMyPin()!)' and official_account<>'1' order by 2 collate nocase asc"
            if self.listFriends {
                query = "SELECT f_pin, first_name, last_name, image_id, user_type, official_account, ex_offmp FROM BUDDY where f_pin <> '\(User.getMyPin()!)' order by 2 collate nocase asc"
            }
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: query) {
                        while cursor.next() {
                            let user = User(pin: cursor.string(forColumnIndex: 0) ?? "",
                                            firstName: cursor.string(forColumnIndex: 1) ?? "",
                                            lastName: cursor.string(forColumnIndex: 2) ?? "",
                                            thumb: cursor.string(forColumnIndex: 3) ?? "",
                                            userType: cursor.string(forColumnIndex: 4) ?? "",
                                            official: cursor.string(forColumnIndex: 5) ?? "",
                                            ex_offmp: cursor.string(forColumnIndex: 6) ?? "")
                            if (user.firstName + " " + user.lastName).trimmingCharacters(in: .whitespaces) == "USR\(user.pin)" {
                                continue
                            }
                            contacts.append(user)
                        }
                        cursor.close()
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
            var dataContacts = contacts.filter { !self.selectedUser.contains($0) }
            if self.listFriends {
                dataContacts.sort(by: { Int($0.official!)! > Int($1.official!)! })
            }
            completion(dataContacts)
        }
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        fillteredUser = users.filter({ d in
            let name = d.fullName.trimmingCharacters(in: .whitespaces)
            return name.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user: User
        if isFilltering {
            user = fillteredUser[indexPath.row]
        } else {
            user = users[indexPath.row]
        }
        if !listFriends {
            tableView.deselectRow(at: indexPath, animated: false)
            user.isSelected = true
            tableView.reloadRows(at: [indexPath], with: .none)
        }
        if isInviteCC {
            if !listFriends {
                self.isDismiss?(user)
                self.navigationController?.popViewController(animated: true)
            } else {
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
                controller.data = user.pin
                controller.flag = .friend
                controller.isBNI = true
                controller.isDismiss = {
                    self.getContacts { users in
                        self.users.removeAll()
                        self.users.append(contentsOf: users)
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
                show(controller, sender: nil)
            }
        } else {
            dismiss(animated: true) {
                self.isDismiss?(user)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFilltering {
            return fillteredUser.count
        }
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let user: User
        if isFilltering {
            user = fillteredUser[indexPath.row]
        } else {
            user = users[indexPath.row]
        }
        content.imageProperties.maximumSize = CGSize(width: 44, height: 44)
        getImage(name: user.thumb, placeholderImage: UIImage(named: "Profile---Black", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
            content.image = image
        }
        if User.isOfficial(official_account: user.official ?? "") || User.isOfficialRegular(official_account: user.official ?? "") {
            content.attributedText = self.set(image: UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(user.fullName)", size: 15, y: -4, colorText: UIColor.officialColor)
            
        } else if User.isVerified(official_account: user.official ?? "") {
            content.attributedText = self.set(image: UIImage(named: "ic_verified", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(user.fullName)", size: 15, y: -4, colorText: UIColor.verifiedColor)
        }
        else if User.isInternal(userType: user.userType ?? "") {
            content.attributedText = self.set(image: UIImage(named: "ic_internal", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(user.fullName)", size: 15, y: -4, colorText: UIColor.internalColor)
        } else if User.isCallCenter(userType: user.userType ?? "") {
            let dataCategory = CategoryCC.getDataFromServiceId(service_id: user.ex_offmp!)
            if dataCategory != nil {
                content.attributedText = self.set(image: UIImage(named: "pb_call_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(user.fullName) (\(dataCategory!.service_name))", size: 15, y: -4, colorText: UIColor.ccColor)
            } else {
                content.attributedText = self.set(image: UIImage(named: "pb_call_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(user.fullName)", size: 15, y: -4, colorText: UIColor.ccColor)
            }
        } else {
            content.text = user.fullName
        }
        cell.contentConfiguration = content
        cell.accessoryType = user.isSelected ? .checkmark : .none
        return cell
    }
    
}

extension QmeraCallContactViewController: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
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
