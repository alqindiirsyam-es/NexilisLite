//
//  SeminarListViewController.swift
//  NexilisLite
//
//  Created by Maronakins on 13/06/23.
//

import UIKit
import nuSDKService

class SeminarListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!

    var searchController: UISearchController!
    
    var data: [SeminarViewer] = []
    
    var fillteredData: [SeminarViewer] = []
    
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isFilltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    var makeSpeaker: ((SeminarViewer) -> ())?
    
    var removeSpeaker: ((SeminarViewer) -> ())?
    
    var timerSearch: Timer?
    
    func filterContentForSearchText(_ searchText: String) {
        fillteredData = data.filter{ $0.name.lowercased().contains(searchText.lowercased()) }
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Seminar".localized()
        
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
        navBarAppearance.titleTextAttributes = attributes
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(cancel(sender:)))
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
//        searchController.searchBar.updateHeight(height: 36, radius: 18)
        searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "Search".localized(), attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)])
//        searchController.searchBar.setMagnifyingGlassColorTo(color: .white)
        searchController.searchBar.setImage(UIImage(), for: .search, state: .normal)
        searchController.searchBar.setPositionAdjustment(UIOffset(horizontal: 10, vertical: 0), for: .search)
        if #unavailable(iOS 26.0) {
            searchController.searchBar.setCustomBackgroundImage(image: UIImage(named: self.traitCollection.userInterfaceStyle == .dark ? "nx_search_bar_dark" : "nx_search_bar", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        }
        searchController.searchBar.tintColor = .mainColor
        
        tableView.delegate = self
        tableView.dataSource = self
        
        definesPresentationContext = true
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    @objc func cancel(sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
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
    
    func showChooserButtonTapped(viewer: SeminarViewer) {
        // Create an instance of the alert controller with the action sheet style
        let alertController = LibAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Add action buttons to the alert controller
        var actionTitle = "Make Speaker"
        if(viewer.isSpeak){
            actionTitle = "Remove Speaker"
        }
        let action = UIAlertAction(title: actionTitle, style: .default) { (_) in
            self.handleSpeaker(viewer: viewer)
        }
        alertController.addAction(action)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func handleSpeaker(viewer: SeminarViewer) {
        navigationController?.dismiss(animated: true)
        if (viewer.isSpeak){
            removeSpeaker!(viewer)
        }
        else {
            makeSpeaker!(viewer)
        }
    }

}

class SeminarListCell: UITableViewCell {
    @IBOutlet weak var imagePerson: UIImageView!
    @IBOutlet weak var speakerButton: UIButton!
    @IBOutlet weak var namePerson: UILabel!
}

// MARK: - Extension

extension SeminarListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewer: SeminarViewer
        if isFilltering {
            viewer = fillteredData[indexPath.row]
        } else {
            viewer = data[indexPath.row]
        }
        showChooserButtonTapped(viewer: viewer)
    }
    
}

extension SeminarListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFilltering {
            return fillteredData.count
        }
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "seminarListCell", for: indexPath) as! SeminarListCell
        cell.imagePerson.layer.masksToBounds = false
        cell.imagePerson.circle()
        cell.imagePerson.clipsToBounds = true
        cell.imagePerson.image = UIImage(named: "Profile---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
        cell.imagePerson.contentMode = .scaleAspectFit
        let user: SeminarViewer
        if isFilltering {
            user = fillteredData[indexPath.row]
        } else {
            user = data[indexPath.row]
        }
        let pictureImage = user.thumb
        if (pictureImage != "") {
            cell.imagePerson.setImage(name: pictureImage)
            cell.imagePerson.contentMode = .scaleAspectFill
        }
        cell.namePerson.text = user.name
        if (user.isSpeak){
            cell.speakerButton.isHidden = false
            cell.speakerButton.setImage(UIImage(named: "pb_seminar_speaking", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
        }
        else if (user.isRaise){
            cell.speakerButton.isHidden = false
            cell.speakerButton.setImage(UIImage(named: "pb_raise_hand", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
        }
        else {
            cell.speakerButton.isHidden = true
        }
        return cell
    }
}

extension SeminarListViewController: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
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
