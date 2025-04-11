//
//  ContactViewController.swift
//  FloatingButtonApp
//
//  Created by Yayan Dwi on 05/08/21.
//

import UIKit
import nuSDKService
import NotificationBannerSwift

class ContactCallViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var dataPersonNotChange: [[String: String?]] = []
    var dataPerson: [[String: String?]] = []
    var fillteredData: [[String: String?]] = []
    var isAddParticipantVideo: Bool = false
    var connectedCall: [[String: String?]] = []
    var isDismiss: (([String: String?]) -> ())?
    var searchController: UISearchController!
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var isFilltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    var onlyAudioOrVideo = 0
    var startWhiteBoard = false
    var startSS = false
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "videoVC") {
            if !Nexilis.checkingAccess(key: "video_call") {
                self.view.makeToast("Feature disabled..".localized(), duration: 3)
                return
            }
            if !CheckConnection.isConnectedToNetwork() {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            let destination = segue.destination as! QmeraVideoViewController
            let index = sender as! UIButton
            destination.dataPerson.append(dataPerson[index.tag])
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Start Call".localized()
        if startWhiteBoard && startSS {
            title = "Start Whiteboard/Screen Sharing".localized()
        } else if onlyAudioOrVideo == 1 {
            title = "Start Audio Call".localized()
        } else if onlyAudioOrVideo == 2 {
            title = "Start Video Call".localized()
        } else if startWhiteBoard {
            title = "Start Whiteboard".localized()
        } else if startSS {
            title = "Start Screen Sharing".localized()
        }
        let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0), NSAttributedString.Key.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.titleTextAttributes = attributes
        if (isAddParticipantVideo) {
            title = "Friends".localized()
        } else {
            let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0), NSAttributedString.Key.foregroundColor: UIColor.white]
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
            navBarAppearance.titleTextAttributes = attributes
            navigationController?.navigationBar.standardAppearance = navBarAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
            let cancel = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(didTapCancel(sender:)))
            navigationItem.leftBarButtonItem = cancel
        }
        let buttonAddFriend = UIBarButtonItem(image: UIImage(systemName: "person.badge.plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default))?.withTintColor(.white), style: .plain, target: self, action: #selector(addFriend(sender:)))
        navigationItem.rightBarButtonItem = buttonAddFriend
        getData()
        dataPersonNotChange = dataPerson
        
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
        searchController.searchBar.setCustomBackgroundImage(image: UIImage(named: self.traitCollection.userInterfaceStyle == .dark ? "nx_search_bar_dark" : "nx_search_bar", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
        searchController.searchBar.tintColor = .mainColor
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        definesPresentationContext = true
        
        tableView.delegate = self
        tableView.dataSource = self
        
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(refresh(notification:)), name: NSNotification.Name(rawValue: "onUpdatePersonInfo"), object: nil)
        
        pullBuddy()
    }
    
    @objc func addFriend(sender: UIBarButtonItem) {
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "addFriendNav") as! UINavigationController
        Utils.addBackground(view: controller.view)
        if let vc = controller.viewControllers.first as? AddFriendTableViewController {
            vc.isDismiss = {
                self.getData()
                self.dataPersonNotChange = self.dataPerson
                self.tableView.reloadData()
            }
        }
        self.navigationController?.present(controller, animated: true, completion: nil)
    }
    
    @objc func refresh(notification: NSNotification) {
        DispatchQueue.main.async {
            //print("MASuK SINI DONG")
            self.getData()
            self.dataPersonNotChange = self.dataPerson
            self.tableView.reloadData()
        }
    }

    @objc func didTapCancel(sender: AnyObject) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapBroadcastButton(sender: AnyObject){
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (!isAddParticipantVideo) {
            let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0), NSAttributedString.Key.foregroundColor: UIColor.white]
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
            navBarAppearance.titleTextAttributes = attributes
            navigationController?.navigationBar.standardAppearance = navBarAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        }
    }
    
    func getData() {
        dataPerson.removeAll()
        let idMe = User.getMyPin() as String?
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_pin, first_name, last_name, official_account, image_id, device_id, offline_mode, user_type, ex_block, ex_offmp FROM BUDDY where official_account<>'1' and f_pin <> '\(idMe!)' order by 4 desc, 2 collate nocase asc") {
                    while cursorData.next() {
                        var row: [String: String?] = [:]
                        row["f_pin"] = cursorData.string(forColumnIndex: 0)
                        if(connectedCall.count > 0 && connectedCall.contains(where: { $0["f_pin"] == row["f_pin"] })) {
                            continue
                        }
                        var name = ""
                        if let firstname = cursorData.string(forColumnIndex: 1) {
                             name = firstname
                        }
                        if let lastname = cursorData.string(forColumnIndex: 2) {
                            name = name + " " + lastname
                        }
                        if name.trimmingCharacters(in: .whitespaces) == "USR\(row["f_pin"]!!)" {
                            continue
                        }
                        row["block"] = cursorData.string(forColumnIndex: 8)
                        if row["block"] == "1" || row["block"] == "-1" {
                            continue
                        }
                        row["name"] = name
                        row["picture"] = cursorData.string(forColumnIndex: 4)
                        row["isOfficial"] = cursorData.string(forColumnIndex: 3)
                        row["deviceId"] = cursorData.string(forColumnIndex: 5)
                        row["isOffline"] = cursorData.string(forColumnIndex: 6)
                        row["user_type"] = cursorData.string(forColumnIndex: 7)
                        row["ex_offmp"] = cursorData.string(forColumnIndex: 7)
                        dataPerson.append(row)
                    }
                    cursorData.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    func filterContentForSearchText(_ searchText: String) {
        fillteredData = self.dataPerson.filter { $0["name"]!!.lowercased().contains(searchText.lowercased()) }
        tableView.reloadData()
    }
    
    private func pullBuddy() {
        if let me = User.getMyPin() {
            DispatchQueue.global().async {
                let _ = Nexilis.write(message: CoreMessage_TMessageBank.getBatchBuddiesInfos(p_f_pin: me, last_update: 0))
            }
        }
    }
}

extension ContactCallViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if startWhiteBoard && startSS {
            return
        } else if (isAddParticipantVideo) {
            UIApplication.shared.visibleViewController?.dismiss(animated: true, completion: {
                self.isDismiss?(self.dataPerson[indexPath.row] as [String: String?])
            })
        } else if startWhiteBoard {
            if !CheckConnection.isConnectedToNetwork() {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "wbVC") as! WhiteboardViewController
            controller.modalPresentationStyle = .overFullScreen
            controller.fromContact = 0
            controller.user = User.getData(pin: self.dataPerson[indexPath.row]["f_pin"]!!)
            present(controller, animated: true, completion: nil)
        } else if startSS {
            if !CheckConnection.isConnectedToNetwork() {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            let controller = ScreenSharingViewController()
            controller.modalPresentationStyle = .overFullScreen
            controller.fromContact = 0
            controller.user = User.getData(pin: self.dataPerson[indexPath.row]["f_pin"]!!)
            present(controller, animated: true, completion: nil)
        }
    }
    
}

extension ContactCallViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFilltering {
            return fillteredData.count
        }
        return dataPersonNotChange.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath ) as! ContactCallCell
        cell.imagePerson.layer.masksToBounds = false
        cell.imagePerson.circle()
        cell.imagePerson.clipsToBounds = true
        cell.imagePerson.image = UIImage(named: "Profile---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
        cell.imagePerson.contentMode = .scaleAspectFit
        if isFilltering {
            dataPerson = fillteredData
        } else {
            dataPerson = dataPersonNotChange
        }
        if dataPerson.count > 0 {
            let pictureImage = dataPerson[indexPath.row]["picture"]!
            if (pictureImage != "" && pictureImage != nil) {
                cell.imagePerson.setImage(name: pictureImage!)
                cell.imagePerson.contentMode = .scaleAspectFill
            }
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            if User.isOfficial(official_account: (dataPerson[indexPath.row]["isOfficial"] ?? "")!) || User.isOfficialRegular(official_account: (dataPerson[indexPath.row]["isOfficial"] ?? "")!) {
                cell.namePerson.attributedText = self.set(image: UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(dataPerson[indexPath.row]["name"]!!)", size: 15, y: -4, colorText: UIColor.officialColor)
                
            } else if User.isVerified(official_account: (dataPerson[indexPath.row]["isOfficial"] ?? "")!) {
                cell.namePerson.attributedText = self.set(image: UIImage(named: "ic_verified", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(dataPerson[indexPath.row]["name"]!!)", size: 15, y: -4, colorText: UIColor.verifiedColor)
            }
            else if User.isInternal(userType: (dataPerson[indexPath.row]["user_type"] ?? "")!) {
                cell.namePerson.attributedText = self.set(image: UIImage(named: "ic_internal", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(dataPerson[indexPath.row]["name"]!!)", size: 15, y: -4, colorText: UIColor.internalColor)
            } else if User.isCallCenter(userType: (dataPerson[indexPath.row]["user_type"] ?? "")!) {
                let dataCategory = CategoryCC.getDataFromServiceId(service_id: (dataPerson[indexPath.row]["ex_offmp"] ?? "")!)
                if dataCategory != nil {
                    cell.namePerson.attributedText = self.set(image: UIImage(named: "pb_call_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(dataPerson[indexPath.row]["name"]!!) (\(dataCategory!.service_name))", size: 15, y: -4, colorText: UIColor.ccColor)
                } else {
                    cell.namePerson.attributedText = self.set(image: UIImage(named: "pb_call_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(dataPerson[indexPath.row]["name"]!!)", size: 15, y: -4, colorText: UIColor.ccColor)
                }
            } else {
                cell.namePerson.text = dataPerson[indexPath.row]["name"] as? String
            }
            if startWhiteBoard && startSS {
                cell.audioCallButton.tag = indexPath.row
                cell.videoCallButton.tag = indexPath.row
                
                cell.audioCallButton.setImage(UIImage(named: "pb_screen_share", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(.mainColor).resize(target: CGSize(width: 35, height: 35)), for: .normal)
                cell.videoCallButton.setImage(UIImage(named: "pb_whiteboard", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(.mainColor).resize(target: CGSize(width: 25, height: 25)), for: .normal)
                
                cell.audioCallButton.addTarget(self, action: #selector(SS(sender:)), for: .touchUpInside)
                cell.videoCallButton.addTarget(self, action: #selector(WB(sender:)), for: .touchUpInside)
            } else if onlyAudioOrVideo == 1 {
                if cell.videoCallButton != nil && cell.videoCallButton.isDescendant(of: cell) {
                    cell.videoCallButton.removeFromSuperview()
                    cell.audioCallButton.removeConstraints(cell.audioCallButton.constraints)
                    cell.audioCallButton.anchor(right: cell.rightAnchor, paddingRight: 20.0, centerY: cell.centerYAnchor)
                }
            } else if startWhiteBoard || startSS {
                cell.audioCallButton.isHidden = true
                cell.videoCallButton.isHidden = true
            } else if onlyAudioOrVideo == 2 {
                cell.audioCallButton.isHidden = true
            } else if (isAddParticipantVideo) {
                cell.audioCallButton.isHidden = true
                cell.videoCallButton.isHidden = true
            } else {
                cell.audioCallButton.tag = indexPath.row
                cell.videoCallButton.tag = indexPath.row
                
                cell.audioCallButton.addTarget(self, action: #selector(call(sender:)), for: .touchUpInside)
                cell.videoCallButton.addTarget(self, action: #selector(videoCall(sender:)), for: .touchUpInside)
            }
        }
        return cell
    }
    
    @objc func call(sender: Any) {
        if !Nexilis.checkingAccess(key: "audio_call") {
            self.view.makeToast("Feature disabled..".localized(), duration: 3)
            return
        }
        let index = sender as! UIButton
        if let pin = dataPerson[index.tag]["f_pin"] {
            if !CheckConnection.isConnectedToNetwork() {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            let controller = QmeraAudioViewController()
            controller.user = User.getData(pin: pin)
            controller.isOutgoing = true
            controller.modalPresentationStyle = .overFullScreen
            present(controller, animated: true, completion: nil)
        }
    }
    
    @objc func videoCall(sender: Any) {
        if !Nexilis.checkingAccess(key: "video_call") {
            self.view.makeToast("Feature disabled..".localized(), duration: 3)
            return
        }
        let index = sender as! UIButton
        if !CheckConnection.isConnectedToNetwork() {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        let videoVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "videoVCQmera") as! QmeraVideoViewController
        videoVC.dataPerson.append(dataPerson[index.tag])
        videoVC.modalPresentationStyle = .overFullScreen
        self.show(videoVC, sender: nil)
    }
    
    @objc func WB(sender: Any) {
        let index = sender as! UIButton
        if let pin = dataPerson[index.tag]["f_pin"] {
            if !CheckConnection.isConnectedToNetwork() {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "wbVC") as! WhiteboardViewController
            controller.modalPresentationStyle = .overFullScreen
            controller.fromContact = 0
            controller.user = User.getData(pin: pin)
            present(controller, animated: true, completion: nil)
        }
    }
    
    @objc func SS(sender: Any) {
        let index = sender as! UIButton
        if let pin = dataPerson[index.tag]["f_pin"] {
            if !CheckConnection.isConnectedToNetwork() {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            let controller = ScreenSharingViewController()
            controller.modalPresentationStyle = .overFullScreen
            controller.fromContact = 0
            controller.user = User.getData(pin: pin)
            present(controller, animated: true, completion: nil)
        }
    }
}

class ContactCallCell: UITableViewCell {
    @IBOutlet weak var imagePerson: UIImageView!
    @IBOutlet weak var videoCallButton: UIButton!
    @IBOutlet weak var audioCallButton: UIButton!
    @IBOutlet weak var namePerson: UILabel!
}

extension ContactCallViewController {
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

extension ContactCallViewController: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
        let cBtn = searchBar.value(forKey: "cancelButton") as! UIButton
        cBtn.setTitle("Cancel".localized(), for: .normal)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }
}
