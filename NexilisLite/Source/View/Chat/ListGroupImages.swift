//
//  ListGroupImages.swift
//  NexilisLite
//
//  Created by Akhmad Al Qindi Irsyam on 28/07/23.
//

import UIKit
import Popover

class ListGroupImages: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var listGroupingImages: [ImageGrouping]!
    var imageTapped: Int!
    var titleName: String!
    let tableViewImages = UITableView()
    var isInitiator = false
    var forwardSession = false
    var deleteSession = false
    var tableViewPopOver = UITableView()
    var popover: Popover!
    var startYVisible: CGFloat!
    var endYVisible: CGFloat!
    var indexSelected = 0
    var updateEditor: (([ImageGrouping], [String: Any?], Bool) -> ())?
    var isSelectAll = false
    var viewMultipleSelect = UIView()
    var constraintBottomViewMultipleSelect: NSLayoutConstraint!
    let centeredTitleView = CenteredTitleSubtitleView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
    var isPersonal = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white

        centeredTitleView.titleLabel.text = titleName
        centeredTitleView.subtitleLabel.text = String(listGroupingImages.count) + " " + "images".localized()
        navigationItem.titleView = centeredTitleView
        
        let selectButton = UIBarButtonItem(title: "Select".localized(), style: .plain, target: self, action: #selector(selectAction))
        selectButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
        navigationItem.rightBarButtonItem = selectButton
        
        tableViewImages.register(UITableViewCell.self, forCellReuseIdentifier: "cellGrupingImages")
        tableViewImages.dataSource = self
        tableViewImages.delegate = self
        tableViewImages.separatorStyle = .none
        self.view.addSubview(tableViewImages)
        tableViewImages.anchor(top: self.view.safeAreaLayoutGuide.topAnchor, left: self.view.safeAreaLayoutGuide.leftAnchor, bottom: self.view.safeAreaLayoutGuide.bottomAnchor, right: self.view.safeAreaLayoutGuide.rightAnchor)
        
        DispatchQueue.main.async {[self] in
            tableViewImages.scrollToRow(at: IndexPath(row: imageTapped, section: 0), at: .top, animated: false)
        }
        
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(onStatusChat(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerStatusChat), object: nil)
        
        self.view.addSubview(viewMultipleSelect)
        viewMultipleSelect.backgroundColor = .white.withAlphaComponent(0.9)
        viewMultipleSelect.anchor(left: self.view.safeAreaLayoutGuide.leftAnchor, right: self.view.safeAreaLayoutGuide.rightAnchor, height: 50)
        constraintBottomViewMultipleSelect = viewMultipleSelect.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 50)
        constraintBottomViewMultipleSelect.isActive = true
    }
    
    @objc func onStatusChat(notification: NSNotification) {
        DispatchQueue.main.async { [self] in
            let data:[AnyHashable : Any] = notification.userInfo!
            if let dataMessage = data["message"] as? TMessage {
                var messageId = dataMessage.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
                messageId = messageId.contains("-2") ? String(messageId.split(separator: ",")[1]) : messageId
                if let idx = listGroupingImages.firstIndex(where: { $0.messageId == messageId }) {
                    listGroupingImages[idx].status = dataMessage.getBody(key: CoreMessage_TMessageKey.STATUS)
                    listGroupingImages[idx].dataMessage["status"] = dataMessage.getBody(key: CoreMessage_TMessageKey.STATUS)
                    tableViewImages.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .none)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == tableViewPopOver {
            return 5
        }
        return listGroupingImages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == tableViewPopOver {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellPopOver", for: indexPath as IndexPath)
            var content = cell.defaultContentConfiguration()
            content.textProperties.font = UIFont.systemFont(ofSize: 14)
            content.imageProperties.tintColor = .black
            switch indexPath.row {
            case 0:
                if listGroupingImages[indexSelected].dataMessage["is_stared"] as! String == "1" {
                    content.image = UIImage(systemName: "star.slash.fill")
                    content.text = "Unstar".localized()
                } else {
                    content.image = UIImage(systemName: "star.fill")
                    content.text = "Star".localized()
                }
            case 1:
                content.image = UIImage(systemName: "arrowshape.turn.up.left.fill")
                content.text = "Reply".localized()
            case 2:
                content.image = UIImage(systemName: "arrowshape.turn.up.right.fill")
                content.text = "Forward".localized()
            case 3:
                content.image = UIImage(systemName: "info.circle.fill")
                content.text = "Info".localized()
            default:
                content.image = UIImage(systemName: "trash.fill")
                content.text = "Delete".localized()
            }
            cell.contentConfiguration = content
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellGrupingImages", for: indexPath as IndexPath)
        cell.contentView.subviews.forEach({ $0.removeFromSuperview() })
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        let containerImages = UIImageView()
        containerImages.contentMode = .scaleAspectFit
        cell.contentView.addSubview(containerImages)
        containerImages.anchor(top: cell.contentView.topAnchor, left: cell.contentView.leftAnchor, right: cell.contentView.rightAnchor, height: ListGroupImages.getImageSize(image: listGroupingImages[indexPath.row].thumbId, screenWidth: UIScreen.main.bounds.width, screenHeight: UIScreen.main.bounds.height)!.height)
        
        if !forwardSession && !deleteSession {
            let longPressRecognizer = LongPressImageVIew(target: self, action: #selector(handleLongPress(_:)))
            longPressRecognizer.imageView = containerImages
            longPressRecognizer.index = indexPath.row
            containerImages.isUserInteractionEnabled = true
            containerImages.addGestureRecognizer(longPressRecognizer)
        }
        
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath = paths.first {
            let imageId = listGroupingImages[indexPath.row].imageId
            let thumbId = listGroupingImages[indexPath.row].thumbId
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(imageId)
            DispatchQueue.main.async {
                let image : UIImage? =  {
                    if let img = Nexilis.imageCache.object(forKey: imageId as NSString) {
                        return img
                    }
                    else if let img = UIImage(contentsOfFile: imageURL.path)?.resize(target: CGSize(width: 1000, height: 1000)) {
                            Nexilis.imageCache.setObject(img, forKey: imageId as NSString)
                            return img
                    }
                    return nil
                }()
                if image == nil {
                    let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(self.listGroupingImages[indexPath.row].thumbId)
                    let image : UIImage? =  {
                        if let img = Nexilis.imageCache.object(forKey: thumbId as NSString) {
                            return img
                        }
                        else if let img = UIImage(contentsOfFile: thumbURL.path)?.resize(target: CGSize(width: 500, height: 500)) {
                                Nexilis.imageCache.setObject(img, forKey: thumbId as NSString)
                                return img
                        }
                        return nil
                    }()
                    containerImages.image = image
                } else {
                    containerImages.image = image
                }
            }
            if !FileManager.default.fileExists(atPath: imageURL.path) {
                let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
                let blurEffectView = UIVisualEffectView(effect: blurEffect)
                blurEffectView.frame = CGRect(x: 0, y: 0, width: containerImages.frame.size.width, height: containerImages.frame.size.height)
                blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                containerImages.addSubview(blurEffectView)
                let imageDownload = UIImageView(image: UIImage(systemName: "arrow.down.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .default)))
                containerImages.addSubview(blurEffectView)
                containerImages.addSubview(imageDownload)
                imageDownload.tintColor = .black.withAlphaComponent(0.3)
                imageDownload.translatesAutoresizingMaskIntoConstraints = false
                imageDownload.centerXAnchor.constraint(equalTo: containerImages.centerXAnchor).isActive = true
                imageDownload.centerYAnchor.constraint(equalTo: containerImages.centerYAnchor).isActive = true
            }
        }
        
        let containerTimeStatus = UIView()
        containerImages.addSubview(containerTimeStatus)
        containerTimeStatus.anchor(bottom: containerImages.bottomAnchor, right: containerImages.rightAnchor, height: 20)
        let widthcontainerTimeStatus = containerTimeStatus.widthAnchor.constraint(equalToConstant: 60)
        widthcontainerTimeStatus.isActive = true
        containerTimeStatus.layer.cornerRadius = 5.0
        containerTimeStatus.layer.masksToBounds = true
        containerTimeStatus.backgroundColor = .black.withAlphaComponent(0.25)
        
        let timeInImage = UILabel()
        containerTimeStatus.addSubview(timeInImage)
        let date = Date(milliseconds: Int64(listGroupingImages[indexPath.row].time) ?? 100)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
        timeInImage.text = formatter.string(from: date as Date)
        timeInImage.textColor = .white
        timeInImage.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        
        if isInitiator {
            let statusInImage = UIImageView()
            containerTimeStatus.addSubview(statusInImage)
            statusInImage.anchor(right: containerTimeStatus.rightAnchor, centerY: containerTimeStatus.centerYAnchor, width: 20, height: 20)
            if listGroupingImages[indexPath.row].status == "1" || listGroupingImages[indexPath.row].status == "2"  {
                statusInImage.image = UIImage(named: "checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.white)
            } else if listGroupingImages[indexPath.row].status == "3" {
                statusInImage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.white)
            } else {
                statusInImage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
            }
            timeInImage.anchor(right: statusInImage.leftAnchor, centerY: containerTimeStatus.centerYAnchor, height: 15)
        } else {
            timeInImage.anchor(right: containerTimeStatus.rightAnchor, paddingRight: 5, centerY: containerTimeStatus.centerYAnchor, height: 20)
            widthcontainerTimeStatus.constant = widthcontainerTimeStatus.constant - 10
        }
        
        if listGroupingImages[indexPath.row].dataMessage["is_stared"] as! String == "1" {
            let iconStar = UIImageView()
            containerTimeStatus.addSubview(iconStar)
            iconStar.anchor(right: timeInImage.leftAnchor, paddingRight: 2, centerY: containerTimeStatus.centerYAnchor, width: 20, height: 20)
            widthcontainerTimeStatus.constant = widthcontainerTimeStatus.constant + 20
            iconStar.image = UIImage(systemName: "star.fill")
            iconStar.tintColor = .white
        }
        
        if deleteSession || forwardSession {
            let containerSelect = UIView()
            containerImages.addSubview(containerSelect)
            containerSelect.anchor(top: containerImages.topAnchor, left: containerImages.leftAnchor, bottom: containerImages.bottomAnchor, right: containerImages.rightAnchor)
            
            let iconSelected = UIImageView(frame: CGRect(x: 0, y: 0, width: 25.0, height: 25.0))
            iconSelected.backgroundColor = .lightGray.withAlphaComponent(0.3)
            iconSelected.layer.borderWidth = 2
            iconSelected.layer.borderColor = UIColor.black.cgColor
            iconSelected.layer.cornerRadius = 12.5
            iconSelected.layer.masksToBounds = true
            iconSelected.tintColor = .black
            containerSelect.addSubview(iconSelected)
            iconSelected.anchor(top: containerSelect.topAnchor, left: containerSelect.leftAnchor, paddingTop: 10, paddingLeft: 10, width: 25.0, height: 25.0)
            
            if listGroupingImages[indexPath.row].isSelected {
                containerSelect.backgroundColor = .white.withAlphaComponent(0.2)
                iconSelected.image = UIImage(systemName: "checkmark.circle.fill")
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == tableViewImages {
            return ListGroupImages.getImageSize(image: listGroupingImages[indexPath.row].thumbId, screenWidth: UIScreen.main.bounds.width, screenHeight: UIScreen.main.bounds.height)!.height + 15
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == tableViewPopOver {
            popover.dismiss()
            switch indexPath.row {
            case 0:
                popover.dismiss()
                if listGroupingImages[indexSelected].dataMessage["is_stared"] as! String == "0" {
                    DispatchQueue.global().async { [self] in
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                    "is_stared" : 1
                                ], _where: "message_id = '\(listGroupingImages[indexSelected].messageId)'")
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                    }
                    listGroupingImages[indexSelected].dataMessage["is_stared"] = "1"
                } else {
                    DispatchQueue.global().async { [self] in
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                    "is_stared" : 0
                                ], _where: "message_id = '\(listGroupingImages[indexSelected].messageId)'")
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                    }
                    listGroupingImages[indexSelected].dataMessage["is_stared"] = "0"
                }
                tableViewImages.reloadRows(at: [IndexPath(row: indexSelected, section: 0)], with: .none)
                updateEditor!(listGroupingImages, [:], false)
            case 1:
                popover.dismiss()
                self.navigationController?.popViewController(animated: true)
                updateEditor!([], listGroupingImages[indexSelected].dataMessage, false)
            case 2:
                popover.dismiss()
                listGroupingImages[indexSelected].isSelected = true
                selectActions(isDeleteSession: false)
            case 3:
                popover.dismiss()
                let messageInfoVC = MessageInfo()
                messageInfoVC.data = listGroupingImages[indexSelected].dataMessage
                if isPersonal {
                    messageInfoVC.dataPerson = listGroupingImages[indexSelected].dataPerson
                } else {
                    messageInfoVC.dataGroup = listGroupingImages[indexSelected].dataGroup
                    messageInfoVC.isPersonal = false
                }
                self.navigationController?.pushViewController(messageInfoVC, animated: true)
            default :
                popover.dismiss()
                listGroupingImages[indexSelected].isSelected = true
                selectActions(isDeleteSession: true)
            }
        } else if deleteSession || forwardSession {
            if listGroupingImages[indexPath.row].isSelected {
                listGroupingImages[indexPath.row].isSelected = false
            } else {
                listGroupingImages[indexPath.row].isSelected = true
            }
            if listGroupingImages.filter({ $0.isSelected }).count != listGroupingImages.count && isSelectAll {
                changetoLeftBarButton(isSelectAllButton: true)
            } else if listGroupingImages.filter({ $0.isSelected }).count == listGroupingImages.count && !isSelectAll {
                changetoLeftBarButton(isSelectAllButton: false)
            }
            viewMultipleSelect.subviews.forEach({ $0.removeFromSuperview() })
            addSubviewMultipleSelect()
            tableView.reloadRows(at: [indexPath], with: .none)
        } else {
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let imageId = listGroupingImages[indexPath.row].imageId
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(imageId)
                if !FileManager.default.fileExists(atPath: imageURL.path) {
                    Download().startHTTP(forKey: listGroupingImages[indexPath.row].imageId) { (name, progress) in
                        guard progress == 100 else {
                            return
                        }
                        
                        let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(self.listGroupingImages[indexPath.row].imageId)
                        let image    = UIImage(contentsOfFile: imageURL.path)
                        let save: Bool = SecureUserDefaults.shared.value(forKey: "saveToGallery") ?? false
                        if save {
                            UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
                        }
                        
                        DispatchQueue.main.async { [self] in
                            tableView.reloadRows(at: [indexPath], with: .none)
                            updateEditor!(listGroupingImages, [:], false)
                        }
                    }
                }
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let visibleRect = CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)
        let visibleTableViewRect = tableViewImages.convert(visibleRect, from: tableViewImages)

        let startY = visibleTableViewRect.origin.y
        let endY = startY + visibleTableViewRect.size.height
        startYVisible = startY
        endYVisible = endY
    }
    
    @objc func handleLongPress(_ gestureRecognizer: LongPressImageVIew) {
        if gestureRecognizer.state == .began {
            indexSelected = gestureRecognizer.index
            let contentOffset = tableViewImages.contentOffset
            let location = gestureRecognizer.location(in: tableViewImages)
            let xTouch = location.x - contentOffset.x
            var yTouch = location.y - contentOffset.y + 100
            
            let boundary = startYVisible != nil ? (endYVisible - startYVisible) / 2 - 50 : (UIScreen.main.bounds.height - 64) / 2 - 50
            let yTouchDiff = startYVisible != nil ? location.y - startYVisible : location.y - 0.0
            
            tableViewPopOver = UITableView(frame: CGRect(x: 0, y: 10, width: 140, height: 220))
            popover = Popover()
            if yTouchDiff >= boundary {
                yTouch = location.y - contentOffset.y + 20
                tableViewPopOver = UITableView(frame: CGRect(x: 0, y: 0, width: 140, height: 220))
                popover.popoverType = .up
            }
            
            tableViewPopOver.register(UITableViewCell.self, forCellReuseIdentifier: "cellPopOver")
            tableViewPopOver.dataSource = self
            tableViewPopOver.delegate = self
            tableViewPopOver.layoutMargins = UIEdgeInsets.zero
            tableViewPopOver.separatorInset = UIEdgeInsets.zero
            tableViewPopOver.isScrollEnabled = false
            
            let viewTable = UITableView(frame: CGRect(x: 0, y: 0, width: 140, height: 220))
            viewTable.addSubview(tableViewPopOver)
            
            let touchPoint = CGPoint( x: xTouch, y: yTouch)
            popover.show(viewTable, point: touchPoint)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    @objc func selectAction() {
        selectActions(isDeleteSession: true)
    }
    
    func selectActions(isDeleteSession: Bool) {
        self.navigationItem.setHidesBackButton(true, animated: true)
        changetoLeftBarButton(isSelectAllButton: true)
        
        let doneButton = UIBarButtonItem(title: "Done".localized(), style: .plain, target: self, action: #selector(doneAction))
        doneButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)], for: .normal)
        navigationItem.rightBarButtonItem = doneButton
        deleteSession = isDeleteSession
        forwardSession = !isDeleteSession
        constraintBottomViewMultipleSelect.constant = 0
        UIView.animate(withDuration: 0.35, animations: {
            self.view.layoutIfNeeded()
        })
        addSubviewMultipleSelect()
        tableViewImages.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        tableViewImages.reloadData()
    }
    
    @objc func selectAllAction() {
        listGroupingImages.forEach({ $0.isSelected = true })
        changetoLeftBarButton(isSelectAllButton: false)
        viewMultipleSelect.subviews.forEach({ $0.removeFromSuperview() })
        addSubviewMultipleSelect()
        tableViewImages.reloadData()
    }
    
    @objc func deselectAllAction() {
        listGroupingImages.forEach({ $0.isSelected = false })
        changetoLeftBarButton(isSelectAllButton: true)
        viewMultipleSelect.subviews.forEach({ $0.removeFromSuperview() })
        addSubviewMultipleSelect()
        tableViewImages.reloadData()
    }
    
    @objc func doneAction() {
        navigationItem.leftBarButtonItem = nil
        let selectButton = UIBarButtonItem(title: "Select".localized(), style: .plain, target: self, action: #selector(selectAction))
        selectButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
        navigationItem.rightBarButtonItem = selectButton
        self.navigationItem.setHidesBackButton(false, animated: true)
        listGroupingImages.forEach({ $0.isSelected = false })
        deleteSession = false
        forwardSession = false
        tableViewImages.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        constraintBottomViewMultipleSelect.constant = 50
        viewMultipleSelect.subviews.forEach({ $0.removeFromSuperview() })
        UIView.animate(withDuration: 0.35, animations: {
            self.view.layoutIfNeeded()
        })
        tableViewImages.reloadData()
    }
    
    func changetoLeftBarButton(isSelectAllButton: Bool) {
        if isSelectAllButton {
            let selectAllButton = UIBarButtonItem(title: "Select All".localized(), style: .plain, target: self, action: #selector(selectAllAction))
            selectAllButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
            navigationItem.leftBarButtonItem = selectAllButton
            isSelectAll = false
        } else {
            let deselectAllButton = UIBarButtonItem(title: "Deselect All".localized(), style: .plain, target: self, action: #selector(deselectAllAction))
            deselectAllButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
            navigationItem.leftBarButtonItem = deselectAllButton
            isSelectAll = true
        }
    }
    
    func addSubviewMultipleSelect() {
        viewMultipleSelect.addTopBorder(with: .lightGray, andWidth: 1)
        let container = UIView()
        viewMultipleSelect.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: viewMultipleSelect.leadingAnchor),
            container.trailingAnchor.constraint(equalTo:viewMultipleSelect.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: viewMultipleSelect.bottomAnchor),
            container.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        let title = UILabel()
        container.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            title.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            title.centerYAnchor.constraint(equalTo:container.centerYAnchor),
        ])
        let countSelected = listGroupingImages.filter({ $0.isSelected }).count
        title.text = "\(countSelected) " + "Selected".localized()
        title.textColor = .mainColor
        title.font = UIFont.systemFont(ofSize: 15.0).bold
        
        let button = UIImageView()
        container.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 15),
            button.centerYAnchor.constraint(equalTo:container.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 30),
            button.heightAnchor.constraint(equalToConstant: 30),
        ])
        if forwardSession {
            button.image = UIImage(systemName: "arrowshape.turn.up.right")
            if countSelected == 0 {
                button.tintColor = .gray
            } else {
                button.tintColor = .mainColor
            }
        } else if deleteSession {
            button.image = UIImage(systemName: "trash")
            if countSelected == 0 {
                button.tintColor = .gray
            } else {
                button.tintColor = .red
            }
        }
        let buttonGesture = UITapGestureRecognizer(target: self, action: #selector(sessionAction))
        button.isUserInteractionEnabled = true
        button.addGestureRecognizer(buttonGesture)
    }
    
    @objc func sessionAction() {
        if forwardSession {
            let tempDataMessages = listGroupingImages.filter({ $0.isSelected })
            var dataMessages: [[String: Any?]] = []
            for i in 0..<tempDataMessages.count {
                dataMessages.append(tempDataMessages[i].dataMessage)
            }
            let contactChatNav = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactChatNav") as! UINavigationController
            Utils.addBackground(view: contactChatNav.view)
            contactChatNav.modalPresentationStyle = .custom
            contactChatNav.navigationBar.tintColor = .white
            contactChatNav.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
            contactChatNav.navigationBar.isTranslucent = false
            let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
            contactChatNav.navigationBar.titleTextAttributes = textAttributes
            contactChatNav.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
            if let controller = contactChatNav.viewControllers.first as? ContactChatViewController {
                controller.isChooser = { [weak self] scope, pin in
                    if scope == "3" {
                        let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                        editorPersonalVC.unique_l_pin = pin
                        editorPersonalVC.dataMessageForward = dataMessages
                        self?.navigationController?.replaceAllViewController(with: editorPersonalVC, animated: true)
                    } else {
                        let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                        editorGroupVC.unique_l_pin = pin
                        editorGroupVC.dataMessageForward = dataMessages
                        self?.navigationController?.replaceAllViewController(with: editorGroupVC, animated: true)
                    }
                }
            }
            self.present(contactChatNav, animated: true, completion: nil)
        } else if deleteSession {
            let tempDataMessages = listGroupingImages.filter({ $0.isSelected })
            let countSelected = tempDataMessages.count
            if countSelected == 0 {
                return
            }
            let alertController = LibAlertController(title: "Delete".localized() + " \(countSelected) " + "messages?", message: nil, preferredStyle: .actionSheet)

            if let action = self.actionDelete(for: "me", title: "Delete".localized() + " \(countSelected) " + "For Me".localized(), dataMessages: tempDataMessages) {
                alertController.addAction(action)
            }
            let idMe = User.getMyPin() as String?
            let dataStatusRead = tempDataMessages.filter({ $0.status == "4" })
            if tempDataMessages[0].dataMessage["f_pin"] as? String == idMe && dataStatusRead.count == 0 {
                if let action = self.actionDelete(for: "everyone", title: "Delete".localized() + " \(countSelected) " + "For Everyone".localized(), dataMessages: tempDataMessages) {
                    alertController.addAction(action)
                }
            }
            alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
            self.present(alertController, animated: true)
        }
    }
    
    private func actionDelete(for type: String, title: String, dataMessages: [ImageGrouping]) -> UIAlertAction? {
        return UIAlertAction(title: title, style: .destructive) { [unowned self] _ in
            let tempDataDelete = listGroupingImages
            for i in 0..<dataMessages.count {
                if (type == "me") {
                    if isPersonal {
                        self.deleteMessage(l_pin: dataMessages[i].lPin, message_id: dataMessages[i].messageId, scope: "3", type: "1", chat: "")
                    } else {
                        self.deleteMessage(l_pin: dataMessages[i].dataGroup["group_id"] as! String, message_id: dataMessages[i].messageId, scope: "4", type: "1", chat: dataMessages[i].dataTopic["chat_id"] as! String)
                    }
                    listGroupingImages.removeAll(where: { $0.messageId == dataMessages[i].messageId })
                } else {
                    if isPersonal {
                        self.deleteMessage(l_pin: dataMessages[i].lPin, message_id: dataMessages[i].messageId, scope: "3", type: "2", chat: "")
                    } else {
                        self.deleteMessage(l_pin: dataMessages[i].dataGroup["group_id"] as! String, message_id: dataMessages[i].messageId, scope: "4", type: "2", chat: dataMessages[i].dataTopic["chat_id"] as! String)
                    }
                    if let idxTemp = tempDataDelete!.firstIndex(where: { $0.messageId == dataMessages[i].messageId}) {
                        tempDataDelete![idxTemp].dataMessage["lock"] = "1"
                    }
                    listGroupingImages.removeAll(where: { $0.messageId == dataMessages[i].messageId })
                }
            }
            centeredTitleView.subtitleLabel.text = String(listGroupingImages.count) + " " + "images".localized()
            updateEditor!(type == "me" ? listGroupingImages : tempDataDelete!, [:], true)
            doneAction()
        }
    }
    
    private func deleteMessage(l_pin: String, message_id: String, scope: String, type: String, chat: String) {
        let tmessage = CoreMessage_TMessageBank.deleteMessage(l_pin: l_pin, messageId: message_id, scope: scope, type: type, chat: chat)
        Nexilis.deleteQueueMessage(message: tmessage)
    }
    
    static func getImageSize(image: String, screenWidth: CGFloat, screenHeight: CGFloat) -> CGSize? {
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath = paths.first {
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(image)
            var imagePath = UIImage(contentsOfFile: imageURL.path)
            if imagePath == nil {
                Download().startHTTP(forKey: image) { (name, progress) in
                    guard progress == 100 else {
                        return
                    }
                }
                imagePath = UIImage(named: "Send-Image", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
            }
            let imageWidth = imagePath!.size.width
            let imageHeight = imagePath!.size.height

            // Calculate the aspect ratio of the image
            let aspectRatio = imageWidth / imageHeight

            // Calculate the size to display the image while maintaining its aspect ratio
            var displayWidth: CGFloat = 0.0
            var displayHeight: CGFloat = 0.0

            if imageWidth > imageHeight {
                // Landscape image
                displayWidth = screenWidth
                displayHeight = screenWidth / aspectRatio
            } else {
                // Portrait or square image
                displayHeight = screenHeight
                displayWidth = screenHeight * aspectRatio
            }
            return CGSize(width: displayWidth, height: displayHeight)
        }
        return nil
    }
}

class CenteredTitleSubtitleView: UIView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .white
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }
    
    private func setupSubviews() {
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        
        // Add any constraints or frames you prefer
        // Here's an example using autolayout anchors
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
    }
}

class LongPressImageVIew: UILongPressGestureRecognizer {
    var imageView = UIImageView()
    var index = 0
}
