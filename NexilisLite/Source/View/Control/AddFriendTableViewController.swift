//
//  AddFriendTableViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 23/09/21.
//

import UIKit

class AddFriendTableViewController: UITableViewController {
    
    var searchController: UISearchController!
    
    var data: [User] = []
    
    var fillteredData: [User] = []
    
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isFilltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    var isDismiss: (() -> ())?
    
    var timerSearch: Timer?
    
    func filterContentForSearchText(_ searchText: String) {
        fillteredData = data.filter{ $0.fullName.lowercased().contains(searchText.lowercased()) }
        getDataSearch(searchText: searchText) { data in
            let r = data.filter { $0.fullName.lowercased().contains(searchText.lowercased()) }
            self.fillteredData.append(contentsOf: r.filter { !self.fillteredData.contains($0) })
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        tableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        isDismiss?()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Add Friends".localized()
        
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
        navBarAppearance.titleTextAttributes = attributes
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(cancel(sender:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Scan QR".localized(), style: .plain, target: self, action: #selector(scanQR(sender:)))
        
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
        
        definesPresentationContext = true
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        tableView.tableFooterView = UIView()
        
        self.data.removeAll()
        getData { d in
            self.data = d
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
    }
    
    @objc func cancel(sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func scanQR(sender: Any) {
        let scannerVC = QRScannerController()
        scannerVC.onQRCodeDetected = { qrCode in
            print("Detected QR Code: \(qrCode)")
            self.dismiss(animated: true)
            var isQR = false
            
            
            DispatchQueue.main.async {
                var dataMessage = CoreMessage_TMessageBank.getAddFriendQRCode(fpin: qrCode)
                if Nexilis.checkingAccess(key: "friend_request_approval"){
                    dataMessage = CoreMessage_TMessageBank.getAddFriendRequest(fPin: qrCode)
                }
                if let response = Nexilis.writeAndWait(message: dataMessage, timeout: 1000 * 30) {
                    print(response.toLogString())
                    isQR = true
                }
                
                if isQR {
                    let alert = UIAlertController(title: "Action Successful".localized(), message: Nexilis.checkingAccess(key: "friend_request_approval") ? "Friend request has been sent".localized() : "Successfully added a new friend".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    let alert = UIAlertController(title: "Unable to complete action".localized(), message: "Friend is invalid or not found".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        present(scannerVC, animated: true, completion: nil)
    }
    
    // MARK: - Data source
    
    func getData(completion: @escaping ([User])->()) {
        DispatchQueue.global().async {
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getPersonSuggestion(p_last_seq: "0")),
               response.isOk() {
                let data = response.getBody(key: CoreMessage_TMessageKey.DATA)
                guard !data.isEmpty else {
                    return
                }
                if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: .utf8)!, options: []) as? [[String: String?]] {
                    var users = jsonArray.map { json in
                        User(pin: (json[CoreMessage_TMessageKey.F_PIN] ?? "") ?? "",
                             firstName: (json[CoreMessage_TMessageKey.FIRST_NAME] ?? "") ?? "",
                             lastName: (json[CoreMessage_TMessageKey.LAST_NAME] ?? "") ?? "",
                             thumb: (json[CoreMessage_TMessageKey.THUMB_ID] ?? "") ?? "")
                    }
                    users = users.filter({ $0.fullName != "USR\($0.pin)" })
                    completion(users)
                }
            }
        }
    }
    
    func getDataSearch(searchText: String, completion: @escaping ([User]) -> ()) {
        DispatchQueue.global().async {
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSearchFriend(search_keyword: searchText, limit: "10")), response.isOk() {
                let data = response.getBody(key: CoreMessage_TMessageKey.DATA)
                guard !data.isEmpty else {
                    return
                }
                if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: .utf8)!, options: []) as? [[String: String?]] {
                    var users = jsonArray.map { json in
                        User(pin: (json[CoreMessage_TMessageKey.F_PIN] ?? "") ?? "",
                             firstName: (json[CoreMessage_TMessageKey.FIRST_NAME] ?? "") ?? "",
                             lastName: (json[CoreMessage_TMessageKey.LAST_NAME] ?? "") ?? "",
                             thumb: (json[CoreMessage_TMessageKey.THUMB_ID] ?? "") ?? "")
                    }
                    users = users.filter({ $0.fullName != "USR\($0.pin)" })
                    completion(users)
                }
            }
        }
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
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Suggestions".localized()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user: User
        if isFilltering {
            user = fillteredData[indexPath.row]
        } else {
            user = data[indexPath.row]
        }
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
        controller.flag = .invite
        controller.data = user.pin
        controller.name = user.fullName
        controller.picture = user.thumb
        controller.isDismiss = {
            self.data.removeAll(where: {$0.pin == user.pin})
            if self.isFilltering {
                self.fillteredData.removeAll(where: {$0.pin == user.pin})
            }
            self.tableView.reloadData()
//            self.getData { d in
//                self.data = d
//                DispatchQueue.main.async {
//                    self.tableView.reloadData()
//                }
//            }
        }
        navigationController?.show(controller, sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFilltering {
            return fillteredData.count
        }
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let user: User
        if isFilltering {
            user = fillteredData[indexPath.row]
        } else {
            user = data[indexPath.row]
        }
        content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
        getImage(name: user.thumb, placeholderImage: UIImage(named: "Profile---Black", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
            content.image = image
        })
        content.text = user.fullName
        content.textProperties.font = UIFont.systemFont(ofSize: 14)
        cell.contentConfiguration = content
        return cell
    }
    
}

// MARK: - Extension

extension AddFriendTableViewController: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        timerSearch?.invalidate()
        let currentText = searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if currentText.count >= 2 || currentText.isEmpty {
            timerSearch = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {_ in
                self.filterContentForSearchText(currentText)
            })
        }
    }
}
