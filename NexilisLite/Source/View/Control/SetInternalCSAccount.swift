//
//  SetInternalAccount.swift
//  NexilisLite
//
//  Created by Akhmad Al Qindi Irsyam on 23/02/23.
//

import UIKit
import NotificationBannerSwift

public class SetInternalCSAccount: UITableViewController {
    private var searchController: UISearchController!
    public var isSetCS = false
    
    var fromNotification = false
    
    private var availableUser: [User] = []
    
    private var fillteredUser: [User] = []
    
    private var isSearchBarEmpty: Bool {
        return searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var isFilltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.backButtonTitle = ""
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellCSInternal")
        
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
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        getData { users in
            self.availableUser.append(contentsOf: users)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    @objc func didTapExit() {
        self.dismiss(animated: true, completion: nil)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.topItem?.title = isSetCS ? "Set CS Account".localized()  :"Set Internal Account".localized()
        self.navigationController?.navigationBar.setNeedsLayout()
        self.title = isSetCS ? "Set CS Account".localized()  :"Set Internal Account".localized()
    }
    
    func getData(completion: @escaping ([User]) -> ()) {
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    var r: [User] = []
                    let query =  "SELECT u.f_pin, u.first_name, u.last_name, u.image_id, u.user_type FROM BUDDY u where u.f_pin <> '\(User.getMyPin()!)' and u.official_account <> '1' and u.official_account <> '2' and u.official_account <> '3' order by 2 collate nocase asc"
                    if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                        while cursorData.next() {
                            let user = User(pin: cursorData.string(forColumnIndex: 0) ?? "",
                                                firstName: cursorData.string(forColumnIndex: 1) ?? "",
                                                lastName: cursorData.string(forColumnIndex: 2) ?? "",
                                                thumb: cursorData.string(forColumnIndex: 3) ?? "",
                                                userType: cursorData.string(forColumnIndex: 4) ?? "")
                            if (user.firstName + " " + user.lastName).trimmingCharacters(in: .whitespaces) == "USR\(user.pin)" {
                                continue
                            }
                            if r.first(where: {$0.pin == user.pin}) == nil {
                                r.append(user)
                            }
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
    
    private func setInternalCS(user: User) {
        let alert = LibAlertController(title: "", message: "Are you sure want to set".localized() + " \(user.fullName) " + (isSetCS ? "become CS Account?".localized() : "become Internal Account?".localized()), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No".localized(), style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes".localized(), style: .default, handler: {(_) in
            Nexilis.showLoader()
            Database.shared.database?.inTransaction({ fmdb, rollback in
                do {
                    if let result = Nexilis.writeSync(message: CoreMessage_TMessageBank.getManagementContactCenter(user_type: (self.isSetCS ? "1" : "3"), l_pin: user.pin), timeout: 5000) {
                        if result.isOk() {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Successfully changed".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                banner.show()
                                self.getData { users in
                                    self.availableUser.removeAll()
                                    self.availableUser.append(contentsOf: users)
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                    }
                                }
                                Nexilis.hideLoader {}
                            })
                        } else {
                            DispatchQueue.main.async {
                                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                                banner.show()
                                Nexilis.hideLoader {}
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                            banner.show()
                        }
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func unsetInternalCS(user: User) {
        let alert = LibAlertController(title: "", message: "Are you sure want to unset".localized() + " \(user.fullName) " + (isSetCS ? "from CS Account?".localized() : "from Internal Account?".localized()), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes".localized(), style: .destructive, handler: {(_) in
            Nexilis.showLoader()
            Database.shared.database?.inTransaction({ fmdb, rollback in
                do {
                    if let result = Nexilis.writeSync(message: CoreMessage_TMessageBank.getManagementContactCenter(user_type: (self.isSetCS ? "0" : "2"), l_pin: user.pin), timeout: 5000) {
                        if result.isOk() {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Successfully changed".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                banner.show()
                                self.getData { users in
                                    self.availableUser.removeAll()
                                    self.availableUser.append(contentsOf: users)
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                    }
                                }
                                Nexilis.hideLoader {}
                            })
                        } else {
                            DispatchQueue.main.async {
                                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                                banner.show()
                                Nexilis.hideLoader {}
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                            banner.show()
                        }
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func filterContentForSearchText(_ searchText: String) {
        fillteredUser = availableUser.filter({ d in
            let name = "\(d.firstName) \(d.lastName)".trimmingCharacters(in: .whitespaces)
            return name.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }

    // MARK: - Table view data source

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableUser.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellCSInternal", for: indexPath as IndexPath)
        var content = cell.defaultContentConfiguration()
        let user: User
        if isFilltering {
            user = fillteredUser[indexPath.row]
        } else {
            user = availableUser[indexPath.row]
        }
        content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
        getImage(name: user.thumb, placeholderImage: UIImage(named: "Profile---Black", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
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
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if !CheckConnection.isConnectedToNetwork() {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        let user: User
        if isFilltering {
            user = fillteredUser[indexPath.row]
        } else {
            user = availableUser[indexPath.row]
        }
        if User.isCallCenter(userType: user.userType!) || (User.isInternal(userType: user.userType!) && !isSetCS) {
            unsetInternalCS(user: user)
        } else {
            if Utils.getDefaultCC() == "No" {
                let viewSetOfficer = SetOfficerBNI()
                viewSetOfficer.f_pin = user.pin
                viewSetOfficer.name = user.fullName
                viewSetOfficer.modalTransitionStyle = .crossDissolve
                viewSetOfficer.modalPresentationStyle = .custom
                self.present(viewSetOfficer, animated: true)
            } else {
                setInternalCS(user: user)
            }
        }
    }
}

extension SetInternalCSAccount: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    public func updateSearchResults(for searchController: UISearchController) {
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
