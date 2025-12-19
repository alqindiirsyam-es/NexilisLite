//
//  QmeraUserStreamingTableViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 02/11/21.
//

import UIKit

class QmeraUserChooserViewController: UITableViewController {

    private var searchController: UISearchController!
    
    var ignored: [User] = []
    
    var isDismiss: (([User]) -> ())?
    
    private var availableUser: [User] = []
    
    private var fillteredUser: [User] = []
    
    private var isSearchBarEmpty: Bool {
        return searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var isFilltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    private var userSelected: [User] = []

    private let cellIdentifier = "reuseIdentifier"
    
    lazy var table: UITableView = {
        let tableView = UITableView(frame: CGRect.zero)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Friends".localized()
        
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add(sender:)))
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self
        searchController.searchBar.updateHeight(height: 36, radius: 18)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "Search".localized(), attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)])
        
        definesPresentationContext = true
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        
        tableView = table
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.getData { users in
                self.availableUser.append(contentsOf: users)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        pullBuddy()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    @objc func add(sender: Any) {
        isDismiss?(userSelected)
        navigationController?.popViewController(animated: true)
    }
    
    private func pullBuddy() {
        if let me = User.getMyPin() {
            DispatchQueue.global().async {
                let _ = Nexilis.write(message: CoreMessage_TMessageBank.getBatchBuddiesInfos(p_f_pin: me, last_update: 0))
            }
        }
    }
    
    // MARK: - Data source
    
    private func getData(completion: @escaping ([User]) -> ()) {
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    var r: [User] = []
                    if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_pin, first_name, last_name, image_id FROM BUDDY where f_pin not in (\(self.ignored.map{ "'\($0.pin)'" }.joined(separator: ","))) and f_pin <> '\(User.getMyPin()!)' and official_account <> 1 order by 2 collate nocase asc") {
                        while cursorData.next() {
                            let user = User(pin: cursorData.string(forColumnIndex: 0) ?? "",
                                                firstName: cursorData.string(forColumnIndex: 1) ?? "",
                                                lastName: cursorData.string(forColumnIndex: 2) ?? "",
                                                thumb: cursorData.string(forColumnIndex: 3) ?? "")
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
    
    private func filterContentForSearchText(_ searchText: String) {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
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
        }
        content.text = "\(user.firstName) \(user.lastName)"
        cell.contentConfiguration = content
        cell.accessoryType = user.isSelected ? .checkmark : .none
        return cell
    }

}

extension QmeraUserChooserViewController: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
}
