//
//  ListGroupImages.swift
//  NexilisLite
//
//  Created by Akhmad Al Qindi Irsyam on 28/07/23.
//

import UIKit
import ImageIO
import Popover
import QuickLook
import AVFoundation

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
    /// Asked to open one of the collage's pictures, by message. The conversation answers it the
    /// same way it answers a picture tapped in a bubble, so both arrive at the same screen.
    var openSingle: ((String, UIViewController, UIImageView) -> Void)?

    /// Whether one of the collage's own pictures is the message named.
    func holds(messageId: String) -> Bool {
        return listGroupingImages.contains { $0.messageId == messageId }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Dark, like the viewer this screen leads into. The bar used to be painted in the app's
        // blue, which is what put a slab of colour across the top of a screen that is otherwise
        // nothing but pictures.
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = .black
        makeHeaderTransparent()

        centeredTitleView.titleLabel.text = titleName
        centeredTitleView.subtitleLabel.text = String(listGroupingImages.count) + " " + "images".localized()
        navigationItem.titleView = centeredTitleView

        let selectButton = UIBarButtonItem(title: "Select".localized(), style: .plain, target: self, action: #selector(selectAction))
        selectButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)], for: .normal)
        navigationItem.rightBarButtonItem = selectButton
        
        tableViewImages.register(UITableViewCell.self, forCellReuseIdentifier: "cellGrupingImages")
        tableViewImages.dataSource = self
        tableViewImages.delegate = self
        tableViewImages.separatorStyle = .none
        self.view.addSubview(tableViewImages)
        // Fix: pinned to the safe area, the pictures began below the bar - so the blurred header
        // had nothing but the screen's own black behind it and could never look transparent. It
        // runs the full height now, and an inset keeps the first picture clear of the bar while
        // letting everything scroll underneath it.
        tableViewImages.anchor(top: self.view.topAnchor, left: self.view.safeAreaLayoutGuide.leftAnchor, bottom: self.view.bottomAnchor, right: self.view.safeAreaLayoutGuide.rightAnchor)
        tableViewImages.contentInsetAdjustmentBehavior = .never
        
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
    
    /// Lets the pictures run behind the bar, with the same blur the viewer's header uses.
    private func makeHeaderTransparent() {
        if let bar = navigationController?.navigationBar {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.shadowColor = .clear
            bar.standardAppearance = appearance
            bar.scrollEdgeAppearance = appearance
            bar.compactAppearance = appearance
            bar.isTranslucent = true
            bar.tintColor = .white
            bar.overrideUserInterfaceStyle = .dark
            // An appearance is not the whole story: these are set straight onto the bar by the
            // shared style this screen is opened with, and they paint over a transparent one.
            bar.backgroundColor = .clear
            bar.barTintColor = nil
            bar.shadowImage = UIImage()
            bar.setBackgroundImage(UIImage(), for: .default)
        }
        headerScrimMask.colors = [
            UIColor.black.cgColor,
            UIColor.black.cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor,
            UIColor.black.withAlphaComponent(0.25).cgColor,
            UIColor.clear.cgColor
        ]
        headerScrimMask.locations = [0.0, 0.35, 0.65, 0.85, 1.0]
        headerScrim.layer.mask = headerScrimMask
        headerScrim.alpha = 0.6
        headerScrim.isUserInteractionEnabled = false
        view.addSubview(headerScrim)
    }

    private let headerScrim = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let headerScrimMask = CAGradientLayer()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Re-applied on the way in: this screen shares the conversation's navigation controller,
        // so the bar it left behind is whatever the conversation set.
        makeHeaderTransparent()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Handed back, or the conversation underneath would be left with a see-through bar it
        // never asked for.
        navigationController?.defaultStyle()
    }

    /// How much room the multiple-select bar is taking along the foot, kept so the inset for the
    /// header above can be reapplied without losing it.
    private var tableBottomInset: CGFloat = 0

    private func applyTableInsets() {
        let top = navigationController?.navigationBar.frame.maxY ?? view.safeAreaInsets.top
        let bottom = tableBottomInset + view.safeAreaInsets.bottom
        guard abs(tableViewImages.contentInset.top - top) > 0.5 || abs(tableViewImages.contentInset.bottom - bottom) > 0.5 else {
            return
        }
        let wasAtTop = tableViewImages.contentOffset.y <= -tableViewImages.contentInset.top + 1
        tableViewImages.contentInset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        tableViewImages.scrollIndicatorInsets = tableViewImages.contentInset
        if wasAtTop {
            tableViewImages.setContentOffset(CGPoint(x: 0, y: -top), animated: false)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyTableInsets()
        let height = (navigationController?.navigationBar.frame.maxY ?? 88) + 40
        headerScrim.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: height)
        headerScrimMask.frame = headerScrim.bounds
        view.bringSubviewToFront(headerScrim)
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
        containerImages.anchor(top: cell.contentView.topAnchor, left: cell.contentView.leftAnchor, right: cell.contentView.rightAnchor, height: ListGroupImages.getImageSize(image: listGroupingImages[indexPath.row].thumbId, screenWidth: UIScreen.main.bounds.width, screenHeight: UIScreen.main.bounds.height).height)
        
        if !forwardSession && !deleteSession {
            let longPressRecognizer = LongPressImageVIew(target: self, action: #selector(handleLongPress(_:)))
            longPressRecognizer.imageView = containerImages
            longPressRecognizer.index = indexPath.row
            containerImages.isUserInteractionEnabled = true
            containerImages.addGestureRecognizer(longPressRecognizer)
            // Tapping one of a collage's pictures opens it the way tapping it in the conversation
            // would - full screen, with the rest of the collage along the foot to move between.
            // Before this a tap here did nothing at all; only a long press was listened for.
            let openRecognizer = IndexedTap(target: self, action: #selector(imageTapped(_:)))
            openRecognizer.imageView = containerImages
            openRecognizer.index = indexPath.row
            containerImages.addGestureRecognizer(openRecognizer)
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
                    do {
                        if let img = Nexilis.imageCache.object(forKey: imageId as NSString) {
                            return img
                        }
                        else if let img = UIImage(contentsOfFile: imageURL.path)?.resize(target: CGSize(width: 1000, height: 1000)) {
                            Nexilis.imageCache.setObject(img, forKey: imageId as NSString)
                            return img
                        } else if var imgData = try FileEncryption.shared.readSecure(filename: imageId) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: imgData)
                            if dataDecrypt != nil {
                                imgData = dataDecrypt!
                            }
                            let img = UIImage(data: imgData)?.resize(target: CGSize(width: 1000, height: 1000))
                            Nexilis.imageCache.setObject(img!, forKey: imageId as NSString)
                            return img
                        }
                    } catch {
                        
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
            if !FileManager.default.fileExists(atPath: imageURL.path) && !FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
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
        timeInImage.text = DateFormatterPool.shared.string(from: date as Date, format: "HH:mm", localeIdentifier: "id")
        timeInImage.textColor = .white
        timeInImage.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        
        if isInitiator {
            let statusInImage = UIImageView()
            containerTimeStatus.addSubview(statusInImage)
            statusInImage.anchor(right: containerTimeStatus.rightAnchor, centerY: containerTimeStatus.centerYAnchor, width: 20, height: 20)
            if listGroupingImages[indexPath.row].status == "1" {
                statusInImage.image = UIImage(systemName: "clock.arrow.circlepath")!.withTintColor(UIColor.white, renderingMode: .alwaysOriginal)

            } else if listGroupingImages[indexPath.row].status == "2"  {
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
            return ListGroupImages.getImageSize(image: listGroupingImages[indexPath.row].thumbId, screenWidth: UIScreen.main.bounds.width, screenHeight: UIScreen.main.bounds.height).height + 15
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
                if !FileManager.default.fileExists(atPath: imageURL.path) && !FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
                    Download().startHTTP(forKey: listGroupingImages[indexPath.row].imageId) { (name, progress) in
                        guard progress == 100 else {
                            return
                        }
                        DispatchQueue.main.async { [self] in
                            tableView.reloadRows(at: [indexPath], with: .none)
                            updateEditor!(listGroupingImages, [:], false)
                        }
                    }
                } else if FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
                    do {
                        if var data = try FileEncryption.shared.readSecure(filename: imageURL.lastPathComponent) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                            if dataDecrypt != nil {
                                data = dataDecrypt!
                            }
                            let image = UIImage(data: data ?? Data())
                            let imageViewer = MediaViewerViewController()
                            imageViewer.media = .image(image ?? UIImage())
                            
                            let navigationController = UINavigationController(rootViewController: imageViewer)
                            navigationController.defaultStyle()
                            navigationController.view.backgroundColor = .clear
                            navigationController.modalPresentationCapturesStatusBarAppearance = true
                            navigationController.modalPresentationStyle = .overFullScreen
                            
                            let backAction = UIAction { _ in
                                navigationController.dismiss(animated: true)
                            }
                            let backButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "chevron.backward"), primaryAction: backAction, menu: nil)
                            imageViewer.navigationItem.leftBarButtonItem = backButton
//                            if Nexilis.checkingAccess(key: "secure_folder_share") || sender.specFile.contains("download") || sender.specFile.contains("share") {
//                                let shareAction = UIAction { _ in
//                                    var activityViewController = UIActivityViewController(activityItems: [image ?? UIImage()], applicationActivities: nil)
//                                    if type == 1 {
//                                        activityViewController = UIActivityViewController(activityItems: [url ?? URL(string: "")!], applicationActivities: nil)
//                                    }
//                                    activityViewController.popoverPresentationController?.sourceView = imageViewer.view
//                                    imageViewer.present(activityViewController, animated: true, completion: nil)
//                                }
//                                let shareButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "square.and.arrow.up"), primaryAction: shareAction, menu: nil)
//                                imageViewer.navigationItem.rightBarButtonItem = shareButton
//                            }
//                            
//                            let name = (dataGroup["f_name"] as? String ?? "") + " (\(dataTopic["title"] as? String ?? ""))"
//                            imageViewer.title = name
                            
                            let transitionDelegate = ZoomTransitioningDelegate()
//                            transitionDelegate.originImageView = sender.imageView
                            navigationController.transitioningDelegate = transitionDelegate
//                            self.transitioningDelegateRef = transitionDelegate
                            
                            present(navigationController, animated: true) {
                                imageViewer.animateBackgroundIn()
                            }
                        }
                    } catch{
                        
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
    
    /// Opens one of the collage's pictures.
    ///
    /// Handed straight back to the conversation rather than opened here. This screen used to build
    /// a viewer of its own, and a viewer built in two places is two viewers - the one from a
    /// collage had no All Media, no Go to Message, no star or forward or delete, and closed with a
    /// different animation. The conversation already knows how to open a picture; it does it.
    @objc func imageTapped(_ sender: IndexedTap) {
        let index = sender.index
        guard index >= 0, index < listGroupingImages.count else {
            return
        }
        // Shown over this screen, growing out of the picture that was tapped - so closing it comes
        // back to the collage rather than dropping past it into the conversation.
        openSingle?(listGroupingImages[index].messageId, self, sender.imageView)
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
        tableBottomInset = 50
        applyTableInsets()
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
        tableBottomInset = 0
        applyTableInsets()
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
    
    /// Sizes already worked out, kept by file name.
    ///
    /// Fix: this used to decode the whole image just to read its width and height, and the chat
    /// bubbles asked for it twice each - once for the height and once for the width - on every
    /// pass over a cell. Decoding a photo to measure it is the most expensive way to do it; the
    /// dimensions sit in the file's header and can be read without touching the pixels.
    private static var measuredSizes: [String: CGSize] = [:]
    private static let measuredSizesLock = NSLock()

    /// What a picture is given until its thumbnail has arrived.
    ///
    /// Fix: an image with nothing downloaded yet was measured as 100x100, and the bubble was
    /// built to that. The moment the thumbnail landed the bubble jumped to the real size, which
    /// moves everything below it - felt as the list lurching while it is being scrolled. A
    /// portrait box of the usual proportions is held instead, so what is reserved is close to
    /// what arrives and the row barely moves.
    private static func placeholderSize(screenWidth: CGFloat, screenHeight: CGFloat) -> CGSize {
        // Square: the picture that arrives is drawn to fill this box, and a square takes the
        // same small bite out of a portrait photo as it does out of a landscape one.
        let side = min(screenWidth, screenHeight)
        return CGSize(width: side, height: side)
    }

    /// The pixel size of an image file, read from its header rather than by decoding it.
    private static func pixelSize(of image: String) -> CGSize? {
        measuredSizesLock.lock()
        let known = measuredSizes[image]
        measuredSizesLock.unlock()
        if let known = known {
            return known
        }

        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let dirPath = paths.first else {
            return nil
        }
        let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(image)
        var size: CGSize?
        if FileManager.default.fileExists(atPath: imageURL.path) {
            if let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
               let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
               let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
               let height = properties[kCGImagePropertyPixelHeight] as? CGFloat {
                size = CGSize(width: width, height: height)
            }
        } else if FileEncryption.shared.isSecureExists(filename: image) {
            // An encrypted file has to be read out before anything can be read from it, but the
            // pixels still do not have to be decoded.
            do {
                if var imageData = try FileEncryption.shared.readSecure(filename: image) {
                    if let decrypted = FileEncryption.shared.decryptFileFromServer(data: imageData) {
                        imageData = decrypted
                    }
                    if let source = CGImageSourceCreateWithData(imageData as CFData, nil),
                       let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                       let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
                       let height = properties[kCGImagePropertyPixelHeight] as? CGFloat {
                        size = CGSize(width: width, height: height)
                    }
                }
            } catch {
                return nil
            }
        }

        guard let size = size, size.width > 0, size.height > 0 else {
            return nil
        }
        measuredSizesLock.lock()
        measuredSizes[image] = size
        measuredSizesLock.unlock()
        return size
    }

    static func getImageSize(
        image: String,
        screenWidth: CGFloat,
        screenHeight: CGFloat
    ) -> CGSize {

        guard let pixels = pixelSize(of: image) else {
            return placeholderSize(screenWidth: screenWidth, screenHeight: screenHeight)
        }

        let aspectRatio = pixels.width / pixels.height
        var displayWidth: CGFloat
        var displayHeight: CGFloat

        if pixels.width > pixels.height {
            displayWidth = screenWidth
            displayHeight = screenWidth / aspectRatio
        } else {
            displayHeight = screenHeight
            displayWidth = screenHeight * aspectRatio
        }

        return CGSize(width: displayWidth, height: displayHeight)
    }
}

class CenteredTitleSubtitleView: UIView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        // Measured off the reference: its title glyphs stand 33px tall on a 3x screen, which is
        // about 15pt once the ascender is accounted for. 18pt also ran straight under the back
        // button on one side and Select on the other, so it is told to shorten rather than
        // overflow as well.
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = .white
        label.lineBreakMode = .byTruncatingTail
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        // 21px against the title's 33 in the reference - a little under two thirds of it.
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = UIColor(white: 1, alpha: 0.75)
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
        // Kept clear of the buttons on either side rather than being allowed to run under them.
        titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor).isActive = true

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1).isActive = true
        subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
    }
}

class LongPressImageVIew: UILongPressGestureRecognizer {
    var imageView = UIImageView()
    var index = 0
}

/// A tap that remembers which picture it landed on.
class IndexedTap: UITapGestureRecognizer {
    var imageView = UIImageView()
    var index = 0
}

// MARK: - The media browser

/// Everything a conversation has ever attached, under three headings: Media, Links and Docs.
///
/// Replaces the old "All Media", which was one long list of full-width pictures - it could not
/// show a conversation's shape, and it had nowhere to put a file or a link at all. The three lists
/// are handed in whole, already read from the database, so nothing here goes near it.
public final class MediaBrowserViewController: UIViewController {

    public struct MediaItem {
        public let messageId: String
        public let thumbFileName: String
        public let mediaFileName: String
        public let isVideo: Bool
        /// Read from the database, where it was written the first time anything had the file open.
        public let durationSeconds: Int
        public let date: Double
        public init(messageId: String, thumbFileName: String, mediaFileName: String = "", isVideo: Bool, durationSeconds: Int = 0, date: Double) {
            self.messageId = messageId
            self.thumbFileName = thumbFileName
            self.mediaFileName = mediaFileName
            self.isVideo = isVideo
            self.durationSeconds = durationSeconds
            self.date = date
        }
    }

    public struct DocItem {
        public let messageId: String
        public let fileName: String
        public let storedName: String
        public let detail: String
        public let date: Double
        public init(messageId: String, fileName: String, storedName: String, detail: String, date: Double) {
            self.messageId = messageId
            self.fileName = fileName
            self.storedName = storedName
            self.detail = detail
            self.date = date
        }
    }

    public struct LinkItem {
        public let messageId: String
        public let url: String
        public let caption: String
        public let thumbFileName: String
        public let date: Double
        public init(messageId: String, url: String, caption: String, thumbFileName: String, date: Double) {
            self.messageId = messageId
            self.url = url
            self.caption = caption
            self.thumbFileName = thumbFileName
            self.date = date
        }
    }

    /// The first web address in a piece of text, if it holds one.
    public static func firstLink(in text: String) -> String? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = detector.firstMatch(in: text, options: [], range: range),
              let url = match.url, url.scheme?.hasPrefix("http") == true else {
            return nil
        }
        return url.absoluteString
    }

    public var media: [MediaItem] = []
    public var docs: [DocItem] = []
    public var links: [LinkItem] = []
    public var conversationName = ""

    public var onOpenMedia: ((String) -> Void)?
    public var onGoToMessage: ((String) -> Void)?
    public var onForward: (([String]) -> Void)?
    public var onDelete: (([String]) -> Void)?

    private enum Tab: Int, Hashable {
        case media, links, docs
    }

    private var currentTab: Tab = .media
    private var scrolledTo: [Tab: CGPoint] = [:]
    private var isSelecting = false
    private var picked = Set<String>()

    /// Which picture the browser was opened on, so it opens showing it rather than at the end of
    /// the conversation, and so the transition has somewhere to shrink into.
    /// What Quick Look is being pointed at, kept alive for as long as it is on screen.
    private var previewURL: NSURL?

    public var focusMessageId = ""
    private var hasFocused = false
    /// A navigation controller holds its delegate weakly, so the transition is kept here.
    public var transitionKeeper: AnyObject?
    /// Whoever was driving the edge swipe before this screen borrowed it.
    private weak var popGestureOwner: UIGestureRecognizerDelegate?

    /// Just a row holding the three floating controls - it paints nothing itself.
    private let header = UIView()

    /// The blur behind that row, fading out downwards.
    ///
    /// Built the same way as the picture viewer's, so the two screens read as one: the thin dark
    /// material, masked by a gradient that decides how far it reaches, and the strength set on the
    /// view's own alpha - alpha composites in proportion, where a part-transparent mask does not.
    /// It is this, not the glass on the controls, that lets white lettering sit over photographs.
    private let headerScrim = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let headerScrimMask = CAGradientLayer()
    private static let headerScrimStrength: CGFloat = 0.6
    private let backButton = UIButton(type: .system)
    private let segments = UISegmentedControl(items: ["Media".localized(), "Links".localized(), "Docs".localized()])
    private let selectButton = UIButton(type: .system)
    private var grid: UICollectionView!
    // Plain rather than grouped: a grouped table sets every section apart with space above the
    // heading and below it, and lets the heading scroll away. Plain has neither gap and pins the
    // heading to the top while its rows go past - which is what the reference does.
    private let list = UITableView(frame: .zero, style: .plain)
    private let searchBar = UISearchBar()
    private var searchText = ""
    /// What the current search leaves of each list. The sections index into these, not the whole.
    private var shownDocs: [DocItem] = []
    private var shownLinks: [LinkItem] = []
    private let footer = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let footerLabel = UILabel()
    private let actionBar = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))

    /// Rows of one list, cut into the months they were sent in.
    private var sections: [(title: String, rows: [Int])] = []

    public override func viewDidLoad() {
        super.viewDidLoad()
        // Dark like the picture viewer it is opened from, rather than following the app: the
        // header is meant to read as the same transparent, blurred strip, and a light strip over
        // a grid of photographs is not that.
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = .black
        navigationController?.setNavigationBarHidden(true, animated: false)
        buildGrid()
        buildList()
        buildSearchField()
        buildHeader()
        buildFooter()
        showTab(.media)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // With the navigation bar hidden UIKit turns the edge swipe off, since there is no back
        // button for it to stand in for. This screen has one of its own, so it is put back.
        popGestureOwner = navigationController?.interactivePopGestureRecognizer?.delegate
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Reaches past the row it sits behind, so it has somewhere to fade out rather than ending
        // on a line across the pictures.
        let scrimHeight = view.safeAreaInsets.top + 44 + 40
        headerScrim.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: scrimHeight)
        headerScrimMask.frame = headerScrim.bounds
        view.bringSubviewToFront(headerScrim)
        view.bringSubviewToFront(header)
        refreshInsets()
        guard !hasFocused, currentTab == .media, grid.bounds.height > 0 else {
            return
        }
        hasFocused = true
        guard let item = media.firstIndex(where: { $0.messageId == focusMessageId }) ?? (media.isEmpty ? nil : media.count - 1) else {
            return
        }
        grid.scrollToItem(at: IndexPath(item: item, section: 0), at: .centeredVertically, animated: false)
        grid.layoutIfNeeded()
        scrolledTo[.media] = grid.contentOffset
    }

    /// The square holding one message, once it is on screen - what a transition grows out of.
    public func tileView(for messageId: String) -> UIImageView? {
        guard let item = media.firstIndex(where: { $0.messageId == messageId }),
              let cell = grid.cellForItem(at: IndexPath(item: item, section: 0)) as? MediaTileCell else {
            return nil
        }
        return cell.picture
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        // Handed back, so nothing else in the stack inherits this screen's arrangement.
        navigationController?.interactivePopGestureRecognizer?.delegate = popGestureOwner
    }

    // MARK: Chrome

    private func buildHeader() {
        // Fix: there was a blurred bar across the whole width here, and no amount of thinning its
        // material was ever going to read as transparent - a bar has the screen's own background
        // behind it, not the pictures. The reference has no bar at all: three controls float over
        // the grid, each carrying its own glass, and the photographs run underneath them.
        headerScrimMask.colors = [
            UIColor.black.cgColor,
            UIColor.black.cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor,
            UIColor.black.withAlphaComponent(0.25).cgColor,
            UIColor.clear.cgColor
        ]
        headerScrimMask.locations = [0.0, 0.35, 0.65, 0.85, 1.0]
        headerScrim.layer.mask = headerScrimMask
        headerScrim.alpha = MediaBrowserViewController.headerScrimStrength
        headerScrim.isUserInteractionEnabled = false
        view.addSubview(headerScrim)

        header.translatesAutoresizingMaskIntoConstraints = false
        header.isUserInteractionEnabled = true
        view.addSubview(header)

        var backStyle = UIButton.Configuration.plain()
        backStyle.image = UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))
        backStyle.contentInsets = .zero
        backButton.configuration = backStyle
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(tapBack), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(backButton)
        glass(behind: backButton, radius: 22)

        segments.selectedSegmentIndex = 0
        segments.backgroundColor = .clear
        segments.selectedSegmentTintColor = UIColor(white: 1, alpha: 0.22)
        // `.semibold` is remapped by the app onto a bold-italic face - which is where the slanted
        // "Media" came from. Plain bold is upright.
        segments.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor(white: 1, alpha: 0.65)], for: .normal)
        segments.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 15), .foregroundColor: UIColor.white], for: .selected)
        segments.setContentHuggingPriority(.required, for: .horizontal)
        segments.addTarget(self, action: #selector(changeTab), for: .valueChanged)
        segments.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(segments)
        glass(behind: segments, radius: 22)

        applySelectTitle()
        selectButton.setContentHuggingPriority(.required, for: .horizontal)
        selectButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        selectButton.addTarget(self, action: #selector(tapSelect), for: .touchUpInside)
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(selectButton)
        glass(behind: selectButton, radius: 22)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 44),

            backButton.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 10),
            backButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            selectButton.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -10),
            selectButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            selectButton.heightAnchor.constraint(equalToConstant: 44),

            // Sized by what is written in it and set beside the back button, not stretched across
            // the gap - the reference leaves empty space between the tabs and Select.
            segments.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            segments.trailingAnchor.constraint(lessThanOrEqualTo: selectButton.leadingAnchor, constant: -8),
            segments.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            segments.heightAnchor.constraint(equalToConstant: 44)
        ])

    }

    private let searchBarHeight: CGFloat = 44

    /// The search field, carried by the list rather than floating over it.
    ///
    /// Fix: it used to be pinned under the header, which meant the list had to be inset past it -
    /// arithmetic that kept leaving a gap before the first heading - and it stayed on screen no
    /// matter how far down the reader went. As part of the list's own content it needs no inset at
    /// all, and it scrolls away on the way up, leaving the floating controls and whichever month
    /// heading has pinned itself beneath them.
    private func buildSearchField() {
        searchBar.placeholder = "Search".localized()
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.tintColor = .white
        searchBar.searchTextField.textColor = .white
        searchBar.searchTextField.backgroundColor = UIColor(white: 1, alpha: 0.1)
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        let carrier = UIView()
        carrier.backgroundColor = .clear
        carrier.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: carrier.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: carrier.leadingAnchor, constant: 6),
            searchBar.trailingAnchor.constraint(equalTo: carrier.trailingAnchor, constant: -6),
            searchBar.heightAnchor.constraint(equalToConstant: searchBarHeight)
        ])
        searchCarrier = carrier
        list.tableHeaderView = carrier
    }

    private var searchCarrier: UIView?

    /// Slides a pane of glass in behind one control, so it reads over the pictures without a bar.
    ///
    /// On iOS 26 that is the real thing - clear glass, which is what the reference is showing.
    /// Before that there is no glass, so the thinnest material stands in for it. What keeps white
    /// lettering readable is not these panes but the scrim behind the whole row.
    private func glass(behind control: UIView, radius: CGFloat) {
        let pane: UIVisualEffectView
        if #available(iOS 26.0, *) {
            pane = UIVisualEffectView(effect: UIGlassEffect(style: .clear))
        } else {
            pane = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        }
        pane.isUserInteractionEnabled = false
        pane.layer.cornerRadius = radius
        pane.layer.cornerCurve = .continuous
        pane.clipsToBounds = true
        pane.translatesAutoresizingMaskIntoConstraints = false
        control.superview?.insertSubview(pane, belowSubview: control)
        NSLayoutConstraint.activate([
            pane.topAnchor.constraint(equalTo: control.topAnchor),
            pane.leadingAnchor.constraint(equalTo: control.leadingAnchor),
            pane.trailingAnchor.constraint(equalTo: control.trailingAnchor),
            pane.bottomAnchor.constraint(equalTo: control.bottomAnchor)
        ])
    }

    private func buildFooter() {
        footer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(footer)
        footerLabel.font = .systemFont(ofSize: 13)
        footerLabel.textColor = .secondaryLabel
        footerLabel.textAlignment = .center
        footerLabel.translatesAutoresizingMaskIntoConstraints = false
        footer.contentView.addSubview(footerLabel)

        actionBar.translatesAutoresizingMaskIntoConstraints = false
        actionBar.isHidden = true
        view.addSubview(actionBar)
        let forward = UIButton(type: .system)
        forward.setImage(UIImage(systemName: "arrowshape.turn.up.right"), for: .normal)
        forward.tintColor = .label
        forward.addTarget(self, action: #selector(tapForward), for: .touchUpInside)
        let bin = UIButton(type: .system)
        bin.setImage(UIImage(systemName: "trash"), for: .normal)
        bin.tintColor = .systemRed
        bin.addTarget(self, action: #selector(tapDelete), for: .touchUpInside)
        let bar = UIStackView(arrangedSubviews: [forward, bin])
        bar.distribution = .fillEqually
        bar.translatesAutoresizingMaskIntoConstraints = false
        actionBar.contentView.addSubview(bar)

        NSLayoutConstraint.activate([
            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            footer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -44),
            footerLabel.centerXAnchor.constraint(equalTo: footer.contentView.centerXAnchor),
            footerLabel.topAnchor.constraint(equalTo: footer.contentView.topAnchor, constant: 14),

            actionBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            actionBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            bar.leadingAnchor.constraint(equalTo: actionBar.contentView.leadingAnchor, constant: 40),
            bar.trailingAnchor.constraint(equalTo: actionBar.contentView.trailingAnchor, constant: -40),
            bar.topAnchor.constraint(equalTo: actionBar.contentView.topAnchor, constant: 8),
            bar.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    private func buildGrid() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        let side = floor((UIScreen.main.bounds.width - 6) / 4)
        layout.itemSize = CGSize(width: side, height: side)
        layout.sectionInset = .zero
        grid = UICollectionView(frame: .zero, collectionViewLayout: layout)
        grid.backgroundColor = .black
        grid.dataSource = self
        grid.delegate = self
        // The inset is measured from the chrome, which already sits below the safe area. Left on
        // automatic, UIKit adds the safe area to it a second time - which is the 65pt of empty
        // black that kept appearing above the search field however the inset was worked out.
        grid.contentInsetAdjustmentBehavior = .never
        grid.register(MediaTileCell.self, forCellWithReuseIdentifier: "tile")
        grid.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: view.topAnchor),
            grid.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            grid.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            grid.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func buildList() {
        list.dataSource = self
        list.delegate = self
        list.contentInsetAdjustmentBehavior = .never
        list.backgroundColor = .black
        list.separatorStyle = .none
        list.sectionHeaderTopPadding = 0
        list.keyboardDismissMode = .onDrag
        list.register(AttachmentRowCell.self, forCellReuseIdentifier: "row")
        list.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(list)
        NSLayoutConstraint.activate([
            list.topAnchor.constraint(equalTo: view.topAnchor),
            list.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            list.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            list.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: Tabs

    @objc private func changeTab() {
        showTab(Tab(rawValue: segments.selectedSegmentIndex) ?? .media)
    }

    private func showTab(_ next: Tab) {
        // Where the tab being left had been scrolled to, so coming back to it lands where it was
        // rather than at the top. Links and Docs share one table, so this cannot be left to the
        // views to remember for themselves.
        rememberScroll()
        currentTab = next
        picked.removeAll()
        refreshSelectionChrome()
        grid.isHidden = next != .media
        list.isHidden = next == .media
        footer.isHidden = next != .media || isSelecting


        switch next {
        case .media:
            footerLabel.text = mediaSummary()
            grid.reloadData()
        case .links, .docs:
            applySearch()
        }
        refreshInsets()
        restoreScroll(top: (next == .media ? grid : list).contentInset.top)
    }

    /// How far down each list starts, measured off the chrome that is actually on screen.
    ///
    /// Fix: these used to be added up from constants - safe area plus a header height plus a
    /// search height - which drifted from where the views really were, leaving the first heading
    /// stranded a long way below the search field. Reading the frames cannot drift.
    private func refreshInsets() {
        setTop(header.frame.maxY + 8, on: grid, bottom: view.safeAreaInsets.bottom + 60)
        setTop(header.frame.maxY + 11, on: list, bottom: view.safeAreaInsets.bottom + 24)

        // A table header view is laid out from its frame, not its constraints, so it is given one.
        // The tail below the field is the gap before the first month heading.
        if let carrier = searchCarrier, list.bounds.width > 0 {
            let height = searchBarHeight + 15
            if carrier.frame.size != CGSize(width: list.bounds.width, height: height) {
                carrier.frame = CGRect(x: 0, y: 0, width: list.bounds.width, height: height)
                carrier.layoutIfNeeded()
                list.tableHeaderView = carrier
            }
        }
    }

    private func setTop(_ top: CGFloat, on scroller: UIScrollView, bottom: CGFloat) {
        guard top > 0, abs(scroller.contentInset.top - top) > 0.5 else {
            return
        }
        // A list sitting at its top should stay there rather than be left showing a gap where the
        // inset used to be.
        let wasAtTop = scroller.contentOffset.y <= -scroller.contentInset.top + 1
        scroller.contentInset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        scroller.scrollIndicatorInsets = scroller.contentInset
        if wasAtTop {
            scroller.setContentOffset(CGPoint(x: 0, y: -top), animated: false)
        }
    }

    /// Rebuilds the list from what the search leaves of it.
    private func applySearch() {
        let needle = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if currentTab == .docs {
            shownDocs = needle.isEmpty ? docs : docs.filter {
                $0.fileName.lowercased().contains(needle) || $0.detail.lowercased().contains(needle)
            }
            sections = Self.groupByMonth(count: shownDocs.count) { self.shownDocs[$0].date }
            list.tableFooterView = countFooter(shownDocs.count, one: "Document".localized(), many: "Documents".localized())
        } else {
            shownLinks = needle.isEmpty ? links : links.filter {
                $0.url.lowercased().contains(needle) || $0.caption.lowercased().contains(needle)
            }
            sections = Self.groupByMonth(count: shownLinks.count) { self.shownLinks[$0].date }
            list.tableFooterView = countFooter(shownLinks.count, one: "Link".localized(), many: "Links".localized())
        }
        list.reloadData()
    }

    /// The tally the reference puts after the last row - part of the list, not a bar over it.
    private func countFooter(_ count: Int, one: String, many: String) -> UIView {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 60))
        label.text = "\(count) " + (count == 1 ? one : many)
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }

    private func rememberScroll() {
        scrolledTo[currentTab] = (currentTab == .media ? grid : list).contentOffset
    }

    private func restoreScroll(top: CGFloat) {
        let target = scrolledTo[currentTab] ?? CGPoint(x: 0, y: -top)
        let scroller: UIScrollView = currentTab == .media ? grid : list
        scroller.layoutIfNeeded()
        // A tab that has grown shorter since it was left would otherwise be scrolled past its end.
        let lowest = max(-top, scroller.contentSize.height + scroller.contentInset.bottom - scroller.bounds.height)
        scroller.setContentOffset(CGPoint(x: 0, y: min(max(target.y, -top), lowest)), animated: false)
    }

    private func mediaSummary() -> String {
        let videos = media.filter { $0.isVideo }.count
        let photos = media.count - videos
        return "\(photos) " + "Photos".localized() + ", \(videos) " + "Videos".localized()
    }

    /// Cuts a run of dated rows into months, newest first, the way the reference groups them.
    private static func groupByMonth(count: Int, date: (Int) -> Double) -> [(title: String, rows: [Int])] {
        var buckets: [(key: String, title: String, rows: [Int])] = []
        for index in stride(from: count - 1, through: 0, by: -1) {
            let stamp = Date(timeIntervalSince1970: date(index) / 1000)
            let key = DateFormatterPool.shared.string(from: stamp, format: "yyyy-MM")
            let sameYear = Calendar.current.component(.year, from: stamp) == Calendar.current.component(.year, from: Date())
            let title = DateFormatterPool.shared.string(from: stamp, format: sameYear ? "MMMM" : "MMMM yyyy")
            if let last = buckets.last, last.key == key {
                buckets[buckets.count - 1].rows.append(index)
            } else {
                buckets.append((key, title, [index]))
            }
        }
        return buckets.map { ($0.title, $0.rows) }
    }

    // MARK: Selecting

    @objc private func tapBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func tapSelect() {
        isSelecting.toggle()
        picked.removeAll()
        refreshSelectionChrome()
        reloadCurrent()
    }

    /// Keeps the button hugging its own words, whichever of the two it is showing.
    private func applySelectTitle() {
        var style = UIButton.Configuration.plain()
        style.attributedTitle = AttributedString(isSelecting ? "Cancel".localized() : "Select".localized(),
                                                 attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 15),
                                                                                 .foregroundColor: UIColor.white]))
        style.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14)
        selectButton.configuration = style
        selectButton.tintColor = .white
    }

    private func refreshSelectionChrome() {
        applySelectTitle()
        actionBar.isHidden = !isSelecting || picked.isEmpty
        footer.isHidden = currentTab != .media || isSelecting
    }

    private func reloadCurrent() {
        if currentTab == .media {
            grid.reloadData()
        } else {
            list.reloadData()
        }
    }

    private func togglePick(_ messageId: String) {
        if picked.contains(messageId) {
            picked.remove(messageId)
        } else {
            picked.insert(messageId)
        }
        refreshSelectionChrome()
    }

    @objc private func tapForward() {
        guard !picked.isEmpty else {
            return
        }
        onForward?(orderedPicked())
    }

    @objc private func tapDelete() {
        guard !picked.isEmpty else {
            return
        }
        onDelete?(orderedPicked())
    }

    /// The chosen messages in the order the conversation has them, not the order they were tapped.
    private func orderedPicked() -> [String] {
        let all = media.map { $0.messageId } + links.map { $0.messageId } + docs.map { $0.messageId }
        return all.filter { picked.contains($0) }
    }
}

extension MediaBrowserViewController: UIGestureRecognizerDelegate {

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Only while there is something to go back to, and never in the middle of choosing.
        return (navigationController?.viewControllers.count ?? 0) > 1 && !isSelecting
    }
}

extension MediaBrowserViewController: UISearchBarDelegate {

    public func searchBar(_ searchBar: UISearchBar, textDidChange text: String) {
        searchText = text
        applySearch()
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension MediaBrowserViewController: QLPreviewControllerDataSource {

    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return previewURL == nil ? 0 : 1
    }

    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return previewURL!
    }
}

extension MediaBrowserViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return media.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tile", for: indexPath) as! MediaTileCell
        let item = media[indexPath.item]
        cell.show(item, selecting: isSelecting, picked: picked.contains(item.messageId))
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = media[indexPath.item]
        guard !isSelecting else {
            togglePick(item.messageId)
            collectionView.reloadItems(at: [indexPath])
            return
        }
        guard let onOpenMedia = onOpenMedia else {
            // Opened from a profile or a group's details, which have no conversation on screen to
            // hand this back to - so the browser opens the picture itself.
            openViewer(at: indexPath.item)
            return
        }
        onOpenMedia(item.messageId)
    }

    /// Shows one of the grid's pictures full screen, with the rest of the grid as its strip.
    private func openViewer(at index: Int) {
        guard index >= 0, index < media.count else {
            return
        }
        let viewer = MediaViewerViewController()
        viewer.stripItems = media.map { item in
            var when = ""
            if item.date > 0 {
                when = DateFormatterPool.shared.string(from: Date(timeIntervalSince1970: item.date / 1000), format: "dd/MM/yy HH:mm")
            }
            return MediaViewerViewController.StripItem(
                messageId: item.messageId,
                thumbFileName: item.thumbFileName,
                mediaFileName: item.mediaFileName,
                isVideo: item.isVideo,
                caption: "",
                title: conversationName,
                subtitle: when,
                isStarred: false)
        }
        viewer.currentStripIndex = index
        if let ready = MediaViewerViewController.loadMedia(for: viewer.stripItems[index]) {
            viewer.media = ready
            viewer.autoPlaysOnOpen = viewer.stripItems[index].isVideo
        }

        let stack = UINavigationController(rootViewController: viewer)
        stack.modalPresentationStyle = .fullScreen
        // Grows out of the square that was tapped, and shrinks back into whichever one the reader
        // has moved to - the grid is on screen the whole time, so both ends can be found.
        let zoom = ZoomTransitioningDelegate()
        zoom.originImageView = tileView(for: media[index].messageId)
        zoom.originProvider = { [weak self, weak viewer] in
            guard let self = self, let viewer = viewer else {
                return nil
            }
            return self.tileView(for: viewer.currentMessageId)
        }
        stack.transitioningDelegate = zoom
        transitionKeeper = zoom
        present(stack, animated: true)
    }
}

extension MediaBrowserViewController: UITableViewDataSource, UITableViewDelegate {

    public func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let strip = UIView()
        strip.backgroundColor = UIColor(white: 0.1, alpha: 1)
        let label = UILabel()
        label.text = sections[section].title
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        strip.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: strip.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: strip.centerYAnchor)
        ])
        return strip
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "row", for: indexPath) as! AttachmentRowCell
        let index = sections[indexPath.section].rows[indexPath.row]
        if currentTab == .docs {
            let doc = shownDocs[index]
            cell.showDoc(doc, selecting: isSelecting, picked: picked.contains(doc.messageId))
        } else {
            let link = shownLinks[index]
            cell.showLink(link, selecting: isSelecting, picked: picked.contains(link.messageId))
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let index = sections[indexPath.section].rows[indexPath.row]
        let messageId = currentTab == .docs ? shownDocs[index].messageId : shownLinks[index].messageId
        guard !isSelecting else {
            togglePick(messageId)
            tableView.reloadRows(at: [indexPath], with: .none)
            return
        }
        // A row here is the thing itself, not a pointer at the conversation: a link opens, a
        // document opens. Reaching the message it came from is what "Go to Message" is for.
        if currentTab == .docs {
            open(shownDocs[index])
        } else if let url = URL(string: shownLinks[index].url) {
            UIApplication.shared.open(url)
        }
    }

    /// Opens a document the conversation is holding, wherever the file is kept.
    ///
    /// Shown from here rather than by handing the message back to the conversation: the reader is
    /// looking at the browser, and a document that opened by way of the conversation would drop
    /// them out of it. A file that was never downloaded has nothing to show, so that one case does
    /// go back - the conversation owns transfers.
    private func open(_ item: DocItem) {
        guard !item.storedName.isEmpty else {
            return
        }
        let plain = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
            .appendingPathComponent(item.storedName)
        if FileManager.default.fileExists(atPath: plain.path) {
            preview(plain)
            return
        }
        if FileEncryption.shared.isSecureExists(filename: item.storedName) {
            do {
                if var data = try FileEncryption.shared.readSecure(filename: item.storedName) {
                    if let plainData = FileEncryption.shared.decryptFileFromServer(data: data) {
                        data = plainData
                    }
                    // Quick Look reads from disk, and what is in the secure store cannot be handed
                    // to it as it stands, so a readable copy is left in caches for it.
                    let temporary = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent(item.storedName)
                    try data.write(to: temporary)
                    preview(temporary)
                    return
                }
            } catch {
                return
            }
        }
        onGoToMessage?(item.messageId)
    }

    private func preview(_ url: URL) {
        previewURL = url as NSURL
        let quickLook = QLPreviewController()
        quickLook.dataSource = self
        present(quickLook, animated: true)
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 74
    }
}

/// One square of the Media grid.
final class MediaTileCell: UICollectionViewCell {

    let picture = UIImageView()
    private let videoBadge = UIImageView(image: UIImage(systemName: "video.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)))
    private let durationLabel = UILabel()
    /// Durations already read, so scrolling back over a video does not open the file again.
    private static var durations: [String: String] = [:]
    private static let durationQueue = DispatchQueue(label: "nexilis.mediabrowser.durations", qos: .utility)
    private var waitingForDuration = ""
    private let tick = UIImageView()
    private let dim = UIView()
    /// What this tile was last asked to load, so a picture arriving late for a tile that has since
    /// been handed to another message is dropped rather than drawn over the new one.
    private var loading = ""
    private static let queue = DispatchQueue(label: "nexilis.mediabrowser.thumbs", qos: .userInitiated, attributes: .concurrent)

    override init(frame: CGRect) {
        super.init(frame: frame)
        picture.contentMode = .scaleAspectFill
        picture.clipsToBounds = true
        picture.backgroundColor = .secondarySystemBackground
        picture.frame = bounds
        picture.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(picture)

        dim.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        dim.frame = bounds
        dim.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dim.isHidden = true
        contentView.addSubview(dim)

        videoBadge.tintColor = .white
        // Fix: this was pinned to 14x10, which is not the shape of the symbol - it came out
        // squashed and, against a busy thumbnail, unreadable. It keeps its own proportions now,
        // with a shadow so it holds up over a pale frame.
        videoBadge.contentMode = .scaleAspectFit
        videoBadge.layer.shadowColor = UIColor.black.cgColor
        videoBadge.layer.shadowOpacity = 0.5
        videoBadge.layer.shadowRadius = 2
        videoBadge.layer.shadowOffset = .zero
        videoBadge.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(videoBadge)

        durationLabel.font = .systemFont(ofSize: 11)
        durationLabel.textColor = .white
        durationLabel.textAlignment = .right
        durationLabel.layer.shadowColor = UIColor.black.cgColor
        durationLabel.layer.shadowOpacity = 0.5
        durationLabel.layer.shadowRadius = 2
        durationLabel.layer.shadowOffset = .zero
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(durationLabel)

        tick.tintColor = .white
        tick.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tick)

        NSLayoutConstraint.activate([
            videoBadge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            videoBadge.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            durationLabel.centerYAnchor.constraint(equalTo: videoBadge.centerYAnchor),
            durationLabel.leadingAnchor.constraint(greaterThanOrEqualTo: videoBadge.trailingAnchor, constant: 2),
            tick.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            tick.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            tick.widthAnchor.constraint(equalToConstant: 20),
            tick.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func show(_ item: MediaBrowserViewController.MediaItem, selecting: Bool, picked: Bool) {
        videoBadge.isHidden = !item.isVideo
        durationLabel.isHidden = !item.isVideo
        if item.isVideo, item.durationSeconds > 0 {
            durationLabel.text = MediaTileCell.spell(item.durationSeconds)
        } else if item.isVideo {
            // Nothing written down for this one yet. If the file is sitting plainly on disk it can
            // be read here and remembered, so the label is there the next time without asking.
            durationLabel.text = MediaTileCell.durations[item.mediaFileName]
            if durationLabel.text == nil {
                askForDuration(of: item.mediaFileName, messageId: item.messageId)
            }
        } else {
            durationLabel.text = nil
        }
        tick.isHidden = !selecting
        tick.image = UIImage(systemName: picked ? "checkmark.circle.fill" : "circle")
        dim.isHidden = !(selecting && picked)

        guard loading != item.thumbFileName else {
            return
        }
        loading = item.thumbFileName
        picture.image = nil
        let name = item.thumbFileName
        guard !name.isEmpty else {
            return
        }
        if let cached = Nexilis.imageCache.object(forKey: name as NSString) {
            picture.image = cached
            return
        }
        MediaTileCell.queue.async { [weak self] in
            guard let image = MediaTileCell.thumbnail(named: name) else {
                return
            }
            Nexilis.imageCache.setObject(image, forKey: name as NSString)
            DispatchQueue.main.async {
                guard let self = self, self.loading == name else {
                    return
                }
                self.picture.image = image
            }
        }
    }

    /// Reads how long a video runs, off the main thread, once per file.
    ///
    /// Only for a file kept plainly on disk. A video in the secure store would have to be read and
    /// decrypted whole before anything could be asked of it, and that is not work a grid of
    /// thumbnails should be starting.
    static func spell(_ seconds: Int) -> String {
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func askForDuration(of name: String, messageId: String) {
        guard !name.isEmpty else {
            return
        }
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let dir = paths.first else {
            return
        }
        let url = URL(fileURLWithPath: dir).appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        waitingForDuration = name
        MediaTileCell.durationQueue.async { [weak self] in
            let seconds = CMTimeGetSeconds(AVURLAsset(url: url).duration)
            guard seconds.isFinite, seconds > 0 else {
                return
            }
            let whole = Int(seconds.rounded())
            let text = MediaTileCell.spell(whole)
            MediaViewerViewController.rememberVideoDuration(seconds: whole, messageId: messageId)
            DispatchQueue.main.async {
                MediaTileCell.durations[name] = text
                // The cell may have been handed to another picture while the file was being read.
                guard let self = self, self.waitingForDuration == name else {
                    return
                }
                self.durationLabel.text = text
            }
        }
    }

    /// Reads a thumbnail from wherever it is kept - plainly on disk, or in the secure store.
    private static func thumbnail(named name: String) -> UIImage? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let dir = paths.first {
            let url = URL(fileURLWithPath: dir).appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                return UIImage(contentsOfFile: url.path)?.resize(target: CGSize(width: 300, height: 300))
            }
        }
        if FileEncryption.shared.isSecureExists(filename: name) {
            do {
                if var data = try FileEncryption.shared.readSecure(filename: name) {
                    if let plain = FileEncryption.shared.decryptFileFromServer(data: data) {
                        data = plain
                    }
                    return UIImage(data: data)?.resize(target: CGSize(width: 300, height: 300))
                }
            } catch {
                return nil
            }
        }
        return nil
    }
}

/// One row of the Links or Docs list.
final class AttachmentRowCell: UITableViewCell {

    private let badge = UIView()
    private let badgeLabel = UILabel()
    private let thumb = UIImageView()
    private let title = UILabel()
    private let detail = UILabel()
    private let tick = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        badge.backgroundColor = .tertiarySystemFill
        badge.layer.cornerRadius = 8
        badge.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(badge)

        badgeLabel.font = .systemFont(ofSize: 10, weight: .bold)
        badgeLabel.textColor = .secondaryLabel
        badgeLabel.textAlignment = .center
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(badgeLabel)

        thumb.contentMode = .scaleAspectFill
        thumb.clipsToBounds = true
        thumb.layer.cornerRadius = 8
        thumb.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumb)

        title.font = .systemFont(ofSize: 15)
        title.textColor = .label
        title.numberOfLines = 2
        title.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(title)

        detail.font = .systemFont(ofSize: 12)
        detail.textColor = .secondaryLabel
        detail.numberOfLines = 1
        detail.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(detail)

        tick.tintColor = .systemBlue
        tick.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tick)

        NSLayoutConstraint.activate([
            badge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            badge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            badge.widthAnchor.constraint(equalToConstant: 46),
            badge.heightAnchor.constraint(equalToConstant: 52),
            badgeLabel.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            badgeLabel.centerYAnchor.constraint(equalTo: badge.centerYAnchor),

            thumb.leadingAnchor.constraint(equalTo: badge.leadingAnchor),
            thumb.topAnchor.constraint(equalTo: badge.topAnchor),
            thumb.widthAnchor.constraint(equalTo: badge.widthAnchor),
            thumb.heightAnchor.constraint(equalTo: badge.heightAnchor),

            title.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 12),
            title.trailingAnchor.constraint(equalTo: tick.leadingAnchor, constant: -8),
            title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            detail.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            detail.trailingAnchor.constraint(equalTo: title.trailingAnchor),
            detail.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 3),

            tick.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tick.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            tick.widthAnchor.constraint(equalToConstant: 22),
            tick.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func showDoc(_ item: MediaBrowserViewController.DocItem, selecting: Bool, picked: Bool) {
        thumb.isHidden = true
        badge.isHidden = false
        let kind = (item.fileName as NSString).pathExtension.lowercased()
        badgeLabel.text = kind.isEmpty ? "DOC" : String(kind.prefix(4)).uppercased()
        badgeLabel.textColor = kind == "pdf" ? .systemRed : .secondaryLabel
        title.text = item.fileName
        // The size travels with the message; the kind is read off the name so a file that never
        // carried one still says what it is.
        detail.text = [item.detail, kind].filter { !$0.isEmpty }.joined(separator: " • ")
        applyTick(selecting: selecting, picked: picked)
    }

    func showLink(_ item: MediaBrowserViewController.LinkItem, selecting: Bool, picked: Bool) {
        badge.isHidden = false
        badgeLabel.text = "LINK"
        badgeLabel.textColor = .secondaryLabel
        thumb.isHidden = item.thumbFileName.isEmpty
        thumb.image = item.thumbFileName.isEmpty ? nil : Nexilis.imageCache.object(forKey: item.thumbFileName as NSString)
        title.text = URL(string: item.url)?.host ?? item.url
        detail.text = item.url
        applyTick(selecting: selecting, picked: picked)
    }

    private func applyTick(selecting: Bool, picked: Bool) {
        tick.isHidden = !selecting
        tick.image = UIImage(systemName: picked ? "checkmark.circle.fill" : "circle")
        tick.tintColor = picked ? .systemBlue : .tertiaryLabel
    }
}

/// Grows a picture out of its square in the grid, and shrinks it back into it.
///
/// The reference does not slide the browser in from the side: the picture being looked at settles
/// down into its own tile, and a tile chosen there opens back out. Which square that is cannot be
/// worked out ahead of time - the grid has to have laid out and scrolled to it first - so both
/// ends are asked for at the moment the animation starts rather than handed over in advance.
final class MediaGridZoomAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private let isEntering: Bool
    private weak var viewer: MediaViewerViewController?
    private weak var browser: MediaBrowserViewController?
    private let messageId: String

    init(entering: Bool, viewer: MediaViewerViewController?, browser: MediaBrowserViewController?, messageId: String) {
        self.isEntering = entering
        self.viewer = viewer
        self.browser = browser
        self.messageId = messageId
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.36
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to),
              let fromVC = transitionContext.viewController(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }
        let container = transitionContext.containerView
        container.addSubview(toVC.view)
        toVC.view.frame = container.bounds
        toVC.view.layoutIfNeeded()

        // Entering, the grid has to be scrolled to the picture before its square has a place on
        // screen to be measured; leaving, the same is true of the viewer's page.
        let picture = viewer?.currentPictureView()
        let tile = browser?.tileView(for: messageId)
        guard let image = picture?.image ?? tile?.image,
              let big = picture, let small = tile else {
            toVC.view.alpha = 0
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                toVC.view.alpha = 1
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
            return
        }

        let travelling = UIImageView(image: image)
        travelling.clipsToBounds = true
        let bigFrame = container.convert(MediaGridZoomAnimator.drawnFrame(of: big), from: big.superview)
        let smallFrame = container.convert(small.bounds, from: small)

        travelling.contentMode = isEntering ? .scaleAspectFit : .scaleAspectFill
        travelling.frame = isEntering ? bigFrame : smallFrame
        container.addSubview(travelling)

        toVC.view.alpha = 0
        fromVC.view.alpha = 1
        big.isHidden = true
        small.isHidden = true

        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.4,
                       options: .curveEaseInOut, animations: {
            travelling.frame = self.isEntering ? smallFrame : bigFrame
            travelling.contentMode = self.isEntering ? .scaleAspectFill : .scaleAspectFit
            toVC.view.alpha = 1
            fromVC.view.alpha = 0
        }, completion: { _ in
            travelling.removeFromSuperview()
            big.isHidden = false
            small.isHidden = false
            fromVC.view.alpha = 1
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }

    /// Where the picture actually is inside its view, which for an aspect-fit image view is not
    /// the view's own bounds - without this a tall picture appears to jump wider as it starts.
    private static func drawnFrame(of view: UIImageView) -> CGRect {
        guard let size = view.image?.size, size.width > 0, size.height > 0 else {
            return view.frame
        }
        let scale = min(view.bounds.width / size.width, view.bounds.height / size.height)
        let drawn = CGSize(width: size.width * scale, height: size.height * scale)
        return CGRect(x: view.frame.origin.x + (view.bounds.width - drawn.width) / 2,
                      y: view.frame.origin.y + (view.bounds.height - drawn.height) / 2,
                      width: drawn.width,
                      height: drawn.height)
    }
}

/// Hands the zoom animator to the viewer's navigation controller for the two moves it applies to.
final class MediaGridTransitionDelegate: NSObject, UINavigationControllerDelegate {

    private weak var viewer: MediaViewerViewController?
    private weak var browser: MediaBrowserViewController?

    init(viewer: MediaViewerViewController, browser: MediaBrowserViewController) {
        self.viewer = viewer
        self.browser = browser
    }

    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let viewer = viewer, let browser = browser else {
            return nil
        }
        // Only the step between these two screens is ours; anything else the stack does keeps the
        // ordinary slide.
        if operation == .push, fromVC === viewer, toVC === browser {
            return MediaGridZoomAnimator(entering: true, viewer: viewer, browser: browser, messageId: viewer.currentMessageId)
        }
        // Nothing of ours for the way back. A custom animator is not interactive, so returning one
        // here took the edge swipe away - and the reference keeps it: the browser slides off to
        // the right under the finger with the picture waiting behind it. Only the way in zooms.
        return nil
    }
}
