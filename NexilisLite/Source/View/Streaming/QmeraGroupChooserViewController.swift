//
//  QmeraGroupStreamingViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 02/11/21.
//

import UIKit

class QmeraGroupStreamingViewController: UITableViewController {

    private var searchController: UISearchController!
    
    var ignored: [Group] = []
    
    var isDismiss: (([Group]) -> ())?
    
    private var available: [Group] = []
    
    private var filltered: [Group] = []
    
    private var isSearchBarEmpty: Bool {
        return searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var isFilltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    private var selected: [Group] = []

    private let cellIdentifier = "reuseIdentifier"
    
    lazy var table: UITableView = {
        let tableView = UITableView(frame: CGRect.zero)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Groups".localized()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
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
        
        getData { d in
            self.available.append(contentsOf: d)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    @objc func add(sender: Any) {
        isDismiss?(selected)
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Data source
    
    private func getData(completion: @escaping ([Group]) -> ()) {
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    var r: [Group] = []
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select g.group_id, g.f_name, g.image_id, g.quote, g.created_by, g.created_date, g.parent, g.group_type, g.is_open, g.official, g.is_education from GROUPZ g where g.group_id not in (\(self.ignored.map{ "'\($0.id)'" }.joined(separator: ","))) order by 9 desc, 2 collate nocase asc") {
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
                            let idMe = User.getMyPin() as String?
                            if let cursorUser = Database.shared.getRecords(fmdb: fmdb, query: "SELECT user_type FROM BUDDY where f_pin='\(idMe!)'"), cursorUser.next() {
                                if cursorUser.string(forColumnIndex: 0) != "23" && cursorUser.string(forColumnIndex: 0) != "24" {
                                    if !group.parent.isEmpty && group.official == "1" {
                                        continue
                                    }
                                }
                                cursorUser.close()
                            }
                            r.append(group)
                        }
                        cursor.close()
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
        filltered = available.filter({ d in
            let name = d.name.trimmingCharacters(in: .whitespaces)
            return name.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group: Group
        if isFilltering {
            group = filltered[indexPath.row]
        } else {
            group = available[indexPath.row]
        }
        group.isSelected = !group.isSelected
        tableView.reloadData()
        if group.isSelected {
            selected.append(group)
        } else {
            if let index = selected.firstIndex(of: group) {
                selected.remove(at: index)
            }
        }
        if selected.count == 1 {
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else if selected.count == 0 {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFilltering {
            return filltered.count
        }
        return available.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        var content = cell.defaultContentConfiguration()
        let group: Group
        if isFilltering {
            group = filltered[indexPath.row]
        } else {
            group = available[indexPath.row]
        }
        content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
        getImage(name: group.profile, placeholderImage: UIImage(named: "group-chat", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
            content.image = image
        }
        content.text = group.name
        cell.contentConfiguration = content
        cell.accessoryType = group.isSelected ? .checkmark : .none
        return cell
    }

}

extension QmeraGroupStreamingViewController: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
}
