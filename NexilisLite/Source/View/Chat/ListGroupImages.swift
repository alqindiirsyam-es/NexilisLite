//
//  ListGroupImages.swift
//  NexilisLite
//
//  Created by Akhmad Al Qindi Irsyam on 28/07/23.
//

import UIKit
import ImageIO
@_implementationOnly import Popover
import QuickLook
import QuickLookThumbnailing
import PDFKit
import WebKit
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

    /// The same pictures, in the same order - one collage being asked about another.
    func holdsSameAs(_ other: ListGroupImages) -> Bool {
        guard let mine = listGroupingImages, let theirs = other.listGroupingImages,
              mine.count == theirs.count else {
            return false
        }
        return zip(mine, theirs).allSatisfy { $0.messageId == $1.messageId }
    }

    /// Puts this list on one of its own pictures, for a reader who is already looking at it.
    ///
    /// Nothing moves if that picture is already there to be seen: the reader put the list where it
    /// is, and a picture closing out of the viewer has to land on the row it is actually over.
    func show(messageId: String) {
        guard let index = listGroupingImages.firstIndex(where: { $0.messageId == messageId }) else {
            return
        }
        imageTapped = index
        guard isViewLoaded, tableViewImages.numberOfRows(inSection: 0) > index else {
            return
        }
        tableViewImages.layoutIfNeeded()
        let row = tableViewImages.rectForRow(at: IndexPath(row: index, section: 0))
        let inset = tableViewImages.adjustedContentInset
        let onScreen = CGRect(x: 0,
                              y: tableViewImages.contentOffset.y + inset.top,
                              width: tableViewImages.bounds.width,
                              height: tableViewImages.bounds.height - inset.top - inset.bottom)
        // Enough of it to aim at, and enough for the reader to recognise: half the row, or half
        // the screen when the row is the larger of the two.
        let enough = min(row.height, onScreen.height) / 2
        guard row.intersection(onScreen).height < enough else {
            return
        }
        tableViewImages.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: false)
    }

    /// The picture of one of the collage's rows, once it is on screen - what a transition grows
    /// out of and shrinks back into.
    func tileView(for messageId: String) -> UIImageView? {
        guard let index = listGroupingImages.firstIndex(where: { $0.messageId == messageId }),
              let cell = tableViewImages.cellForRow(at: IndexPath(row: index, section: 0)) else {
            return nil
        }
        return cell.contentView.subviews.compactMap { $0 as? UIImageView }.first
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
        
        // The jump to the tapped picture is made once the rows have been laid out - see
        // jumpToTappedImage. Doing it here, before any of them has a real height, is what put the
        // third and fourth picture of a collage somewhere other than where they were tapped.
        
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

    /// Whether the screen has been placed at the picture it was opened for - see
    /// `viewDidLayoutSubviews`.
    private var hasPlaced = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // The last of the settling passes, and the end of them.
        jumpToTappedImage()
        hasPlaced = true
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

    /// How many times the jump to the tapped picture has been tried.
    ///
    /// Fix: the jump was made from viewDidLoad, before a single row had been laid out. Rows here
    /// are as tall as the picture they hold - `heightForRowAt` works that out from each
    /// thumbnail's own proportions - so before the pictures have been measured the offset is built
    /// out of guesses: near enough for the first row or two, and further out with every row after
    /// it. That is why tapping the third or fourth picture of a collage opened somewhere else.
    ///
    /// Jumping once the rows have real heights lands on the right one. The heights settle over a
    /// pass or two, because laying out the rows it lands on is what gives them their heights, so
    /// this repeats until the offset stops moving - and gives up rather than chase it for ever.
    private var jumpAttempts = 0

    private func jumpToTappedImage() {
        guard jumpAttempts < 5, let target = imageTapped, target > 0,
              tableViewImages.numberOfRows(inSection: 0) > target else {
            return
        }
        let wanted = tableViewImages.rectForRow(at: IndexPath(row: target, section: 0)).minY
            - tableViewImages.contentInset.top
        guard abs(tableViewImages.contentOffset.y - wanted) > 1 else {
            // Already there: nothing more to chase.
            jumpAttempts = 5
            return
        }
        jumpAttempts += 1
        tableViewImages.scrollToRow(at: IndexPath(row: target, section: 0), at: .top, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyTableInsets()
        // Fix: this went on jumping for the life of the screen. `imageTapped` is the picture the
        // screen was opened at, but it is rewritten while the screen is alive - the viewer over it
        // reports every picture the reader moves to - so any layout afterwards re-applied whatever
        // it had last been set to. The layout that follows closing the viewer did exactly that:
        // the picture finished shrinking into its row and then, one frame later, the list snapped
        // to a different one. Measured off a recording, that single frame changed more of the
        // screen than the entire animation before it. Placing the screen at its opening picture is
        // a one-time job; after that only `show(messageId:)` moves the list, and only when it must.
        if !hasPlaced {
            jumpToTappedImage()
        }
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
            // Fix: this built a viewer of its own here - a second viewer, with no All Media, no Go
            // to Message, no star, forward or delete, and its own way of closing - and it only ever
            // appeared for a picture held in the secure store. A picture sitting plainly on disk
            // selected the row and nothing happened at all. The tap on the picture itself was moved
            // onto the conversation's viewer a while ago and this was left behind, so a touch that
            // landed beside the picture rather than on it, or a swipe that ended as a tap, opened
            // the wrong screen. One viewer, whichever part of the row is touched.
            let imageId = listGroupingImages[indexPath.row].imageId
            let onDisk = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(imageId)
            let isHere = FileManager.default.fileExists(atPath: onDisk.path)
                || FileEncryption.shared.isSecureExists(filename: imageId)
            guard isHere else {
                // Not fetched yet, so the touch is a request for it rather than to look at it.
                Download().startHTTP(forKey: imageId) { (name, progress) in
                    guard progress == 100 else {
                        return
                    }
                    DispatchQueue.main.async { [self] in
                        tableView.reloadRows(at: [indexPath], with: .none)
                        updateEditor!(listGroupingImages, [:], false)
                    }
                }
                return
            }
            // Shown over this screen, growing out of the picture in the row that was touched, the
            // same as tapping the picture directly.
            guard let picture = tableView.cellForRow(at: indexPath)?.contentView.subviews
                .compactMap({ $0 as? UIImageView }).first else {
                return
            }
            openSingle?(listGroupingImages[indexPath.row].messageId, self, picture)
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
    /// Whether the file is here to be measured - false while it is still on its way.
    static func isMeasurable(_ image: String) -> Bool {
        return pixelSize(of: image) != nil
    }

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
        public var isStarred: Bool
        /// Whether the picture or video may leave the app - see canShare(row:).
        public let canShare: Bool
        public init(messageId: String, thumbFileName: String, mediaFileName: String = "", isVideo: Bool, durationSeconds: Int = 0, date: Double,
                    isStarred: Bool = false, canShare: Bool = false) {
            self.messageId = messageId
            self.thumbFileName = thumbFileName
            self.mediaFileName = mediaFileName
            self.isVideo = isVideo
            self.durationSeconds = durationSeconds
            self.date = date
            self.isStarred = isStarred
            self.canShare = canShare
        }
    }

    public struct DocItem {
        public let messageId: String
        public let fileName: String
        public let storedName: String
        /// What was written with the file - its caption. Searched, not shown in the row.
        public let detail: String
        public let date: Double
        public var isStarred: Bool
        /// Whether the file may leave the app - see docItem(fromRow:).
        public let canShare: Bool
        /// What kind of file it is - "pdf", "xlsx" - or "" when neither its name nor its first bytes
        /// say.
        public let kind: String
        public init(messageId: String, fileName: String, storedName: String, detail: String, date: Double,
                    isStarred: Bool = false, canShare: Bool = false, kind: String? = nil) {
            self.messageId = messageId
            self.fileName = fileName
            self.storedName = storedName
            self.detail = detail
            self.date = date
            self.isStarred = isStarred
            self.canShare = canShare
            self.kind = kind ?? Utils.documentExtension(of: fileName)
        }
    }

    /// A document row of the Docs tab, read off a message row: its name (the text before the
    /// first bar), the stored file, the caption after the bar, whether it is starred, and whether
    /// it may be shared - on the same terms the picture viewer offers Share.
    public static func docItem(fromRow row: [String: Any?]) -> DocItem? {
        let file = row["file_id"] as? String ?? ""
        guard !file.isEmpty else {
            return nil
        }
        let text = row["message_text"] as? String ?? ""
        // Fix: the text before the first bar was taken as the name whether or not there was a bar.
        // A document sent from elsewhere often carries only its caption, so the row was named after
        // that sentence and had no extension at all ("*Fandi* dan *Sucipto* adalah ..." where the
        // conversation shows "Activity user BIN.xlsx"). The name and the kind are read the way the
        // conversation reads them - Utils.documentName / documentKind - so the two always agree.
        let name = Utils.documentName(messageText: text, file: file)
        let caption = text.contains("|")
            ? text.components(separatedBy: "|").dropFirst().joined(separator: "|")
            : text
        return DocItem(messageId: row["message_id"] as? String ?? "",
                       fileName: name,
                       storedName: file,
                       detail: caption,
                       date: Double(row["server_date"] as? String ?? "") ?? 0,
                       isStarred: (row["is_stared"] as? String ?? "0") == "1",
                       canShare: canShare(row: row),
                       kind: Utils.documentKind(named: name, file: file))
    }

    /// Whether a message's attachment may leave the app, on the terms the picture viewer offers
    /// Share: never for a confidential message, otherwise where sharing is allowed for everyone or
    /// for this attachment.
    public static func canShare(row: [String: Any?]) -> Bool {
        let speciality = row[TypeDataMessage.spec_file] as? String ?? row["attachment_speciality"] as? String ?? ""
        return (row["credential"] as? String ?? "") != "1"
            && (Nexilis.checkingAccess(key: "secure_folder_share") || speciality.contains("download") || speciality.contains("share"))
    }

    public struct LinkItem {
        public let messageId: String
        public let url: String
        public let caption: String
        public let thumbFileName: String
        public let date: Double
        public var isStarred: Bool
        /// Whether the link may leave the app - not for a message sent as confidential.
        public let canShare: Bool
        /// The link as the conversation wrote it, which is what its unfurled title and picture are
        /// kept under (LINK_PREVIEW) - not always the same text as `url`.
        public let previewKey: String
        public init(messageId: String, url: String, caption: String, thumbFileName: String, date: Double,
                    isStarred: Bool = false, canShare: Bool = true, previewKey: String? = nil) {
            self.messageId = messageId
            self.url = url
            self.caption = caption
            self.thumbFileName = thumbFileName
            self.date = date
            self.isStarred = isStarred
            self.canShare = canShare
            let written = previewKey ?? LinkPreviewFetcher.firstLink(in: caption)
            self.previewKey = written.isEmpty ? url : written
        }
    }

    /// A row of the Links tab, read off a message row that carries a link and no file.
    public static func linkItem(fromRow row: [String: Any?]) -> LinkItem? {
        guard (row["file_id"] as? String ?? "").isEmpty else {
            return nil
        }
        let text = row["message_text"] as? String ?? ""
        guard let url = firstLink(in: text) else {
            return nil
        }
        return LinkItem(messageId: row["message_id"] as? String ?? "",
                        url: url,
                        caption: text,
                        thumbFileName: row["thumb_id"] as? String ?? "",
                        date: Double(row["server_date"] as? String ?? "") ?? 0,
                        isStarred: (row["is_stared"] as? String ?? "0") == "1",
                        canShare: (row["credential"] as? String ?? "") != "1")
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
    /// Stars or unstars one message - offered in a document's menu when the screen that opened
    /// the browser can do it.
    public var onStar: ((String) -> Void)?

    /// Documents being downloaded from this screen, and how far along each is (0-100).
    private var docDownloads: [String: Double] = [:]
    /// What has been found out about each stored file: its size, and a PDF's page count.
    private var docSizes: [String: Int64] = [:]
    private var docPages: [String: Int] = [:]
    private var askedDocFacts = Set<String>()
    /// What has been read about each link's page (its title and picture), by preview key, and the
    /// pages already asked for.
    private var linkAnswers: [String: LinkPreviewStore.Answer] = [:]
    private var askedLinkPages = Set<String>()

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
    private let headerScrim = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
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
    /// The month the grid is passing through, beside the scroll indicator while it moves - as in
    /// WhatsApp and Photos.
    private let monthPill = UIView()
    private let monthPillLabel = UILabel()
    private var monthPillHide: DispatchWorkItem?
    /// The buttons along the bottom while choosing - each on its own glass, as in WhatsApp.
    private let actionBar = UIView()
    private let forwardButton = UIButton(type: .system)
    private let starButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private var forwardHolder: UIView?
    private var footerTop: NSLayoutConstraint?
    private var backGlass: UIView?
    private var segmentsBesideBack: NSLayoutConstraint?
    private var segmentsCentred: NSLayoutConstraint?
    private var selectSquare: NSLayoutConstraint?

    /// Rows of one list, cut into the months they were sent in.
    private var sections: [(title: String, rows: [Int])] = []

    public override func viewDidLoad() {
        super.viewDidLoad()
        // Fix: the screen was held dark whatever the phone was set to. WhatsApp follows it - white
        // in light mode, black in dark, with the text, the month strips and the cards to match - so
        // every colour here is one that answers to the mode (BrowserPalette).
        view.backgroundColor = .systemBackground
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

    /// Brings the square holding this message into view, if it is not there already.
    ///
    /// The reader moves through the pictures inside the viewer, and the one they close on is
    /// usually not the one they opened - its square can be anywhere in the list, including well
    /// off the top of it. Closing then shrank the picture towards a place that could not be seen:
    /// it slid off the screen and vanished. So the list is taken to that square first, and what
    /// is behind the picture as it closes is the picture itself.
    ///
    /// Fix: this centred the square, and it did so every time. Centring a square taller than the
    /// screen leaves the reader looking at the join between two pictures, and doing it every time
    /// moved the list even when the square was already in full view - so closing on the very
    /// picture you had opened left the list halfway between it and the next one, rather than
    /// where you had put it. Nothing moves unless it has to, and when it has to it moves the
    /// least it can.
    public func focus(on messageId: String) {
        guard currentTab == .media,
              let item = media.firstIndex(where: { $0.messageId == messageId }),
              grid.bounds.height > 0,
              let square = grid.layoutAttributesForItem(at: IndexPath(item: item, section: 0)) else {
            return
        }
        let onScreen = CGRect(x: grid.contentOffset.x,
                              y: grid.contentOffset.y + grid.adjustedContentInset.top,
                              width: grid.bounds.width,
                              height: grid.bounds.height - grid.adjustedContentInset.top - grid.adjustedContentInset.bottom)
        // Enough of it to aim at, and enough for the reader to recognise: half the square, or
        // half the screen when the square is the larger of the two.
        let enough = min(square.frame.height, onScreen.height) / 2
        guard square.frame.intersection(onScreen).height < enough else {
            return
        }
        grid.scrollRectToVisible(square.frame, animated: false)
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
        // Fix: a picture opening full screen counts as this screen disappearing, so the bar came
        // back - underneath something covering the whole screen, where nobody could see it - and
        // was hidden again on the way back. Both of those change the room the grid has, and the
        // grid answers by moving its rows. That happened in the middle of the picture flying
        // home, so it flew to where its square had been rather than where it now was. A screen
        // with something presented over it has not been left; only a real departure hands the
        // bar back.
        guard presentedViewController == nil else {
            return
        }
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
        backButton.tintColor = .label
        backButton.addTarget(self, action: #selector(tapBack), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(backButton)
        backGlass = glass(behind: backButton, radius: 22)

        segments.selectedSegmentIndex = 0
        segments.backgroundColor = .clear
        segments.selectedSegmentTintColor = BrowserPalette.selectedSegment
        // `.semibold` is remapped by the app onto a bold-italic face - which is where the slanted
        // "Media" came from. Plain bold is upright.
        segments.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor.label.withAlphaComponent(0.7)], for: .normal)
        // The chosen tab is told by its glass and its full colour, not by weight - as in WhatsApp.
        segments.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor.label], for: .selected)
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
            segments.trailingAnchor.constraint(lessThanOrEqualTo: selectButton.leadingAnchor, constant: -8),
            segments.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            segments.heightAnchor.constraint(equalToConstant: 44)
        ])
        // Beside the back button normally; while choosing there is no back button, and the tabs
        // stand in the middle with a round X at the end, as in WhatsApp.
        segmentsBesideBack = segments.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8)
        segmentsCentred = segments.centerXAnchor.constraint(equalTo: header.centerXAnchor)
        selectSquare = selectButton.widthAnchor.constraint(equalToConstant: 44)
        segmentsBesideBack?.isActive = true
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
        searchBar.tintColor = .label
        searchBar.searchTextField.textColor = .label
        searchBar.searchTextField.backgroundColor = .tertiarySystemFill
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
    @discardableResult
    private func glass(behind control: UIView, radius: CGFloat) -> UIView {
        let pane: UIVisualEffectView
        if #available(iOS 26.0, *) {
            pane = UIVisualEffectView(effect: UIGlassEffect(style: .clear))
        } else {
            pane = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
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
        return pane
    }

    private func buildFooter() {
        // On iOS 26 the count stands on the pictures with nothing behind it, as WhatsApp's does;
        // before that it keeps its blurred strip, which is how that system reads.
        if #available(iOS 26.0, *) {
            footer.effect = nil
            footer.backgroundColor = .clear
        }
        footer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(footer)
        footerLabel.font = .systemFont(ofSize: 17)
        footerLabel.textColor = .label
        footerLabel.textAlignment = .center
        footerLabel.translatesAutoresizingMaskIntoConstraints = false
        footer.contentView.addSubview(footerLabel)

        // WhatsApp's bar while choosing: round glass buttons spread across the bottom - Share,
        // Star and Delete under Media; Forward, Star, Share and Delete under Links and Docs - shown
        // as soon as choosing starts and greyed until something is chosen.
        monthPill.isUserInteractionEnabled = false
        monthPill.alpha = 0
        monthPill.layer.cornerRadius = 14
        monthPill.layer.cornerCurve = .continuous
        monthPill.clipsToBounds = true
        let pillGround: UIVisualEffectView
        if #available(iOS 26.0, *) {
            pillGround = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
        } else {
            pillGround = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        }
        pillGround.frame = monthPill.bounds
        pillGround.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        monthPill.addSubview(pillGround)
        monthPillLabel.font = .systemFont(ofSize: 13, weight: .medium)
        monthPillLabel.textColor = .label
        monthPillLabel.textAlignment = .center
        monthPillLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        monthPill.addSubview(monthPillLabel)
        view.addSubview(monthPill)

        actionBar.translatesAutoresizingMaskIntoConstraints = false
        actionBar.backgroundColor = .clear
        actionBar.isHidden = true
        view.addSubview(actionBar)
        let symbols: [(UIButton, String, Selector)] = [
            (forwardButton, "arrowshape.turn.up.right", #selector(tapForward)),
            (starButton, "star", #selector(tapStarPicked)),
            (shareButton, "square.and.arrow.up", #selector(tapSharePicked)),
            (deleteButton, "trash", #selector(tapDelete))
        ]
        var holders: [UIView] = []
        for (button, symbol, action) in symbols {
            button.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)), for: .normal)
            button.tintColor = .label
            button.addTarget(self, action: action, for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            let holder = UIView()
            holder.translatesAutoresizingMaskIntoConstraints = false
            holder.addSubview(button)
            NSLayoutConstraint.activate([
                holder.widthAnchor.constraint(equalToConstant: 48),
                holder.heightAnchor.constraint(equalToConstant: 48),
                button.topAnchor.constraint(equalTo: holder.topAnchor),
                button.bottomAnchor.constraint(equalTo: holder.bottomAnchor),
                button.leadingAnchor.constraint(equalTo: holder.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: holder.trailingAnchor)
            ])
            glass(behind: button, radius: 24)
            holders.append(holder)
        }
        forwardHolder = holders.first
        let bar = UIStackView(arrangedSubviews: holders)
        bar.axis = .horizontal
        bar.distribution = .equalSpacing
        bar.alignment = .center
        bar.translatesAutoresizingMaskIntoConstraints = false
        actionBar.addSubview(bar)

        footerTop = footer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -44)
        NSLayoutConstraint.activate([
            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            footerTop!,
            footerLabel.centerXAnchor.constraint(equalTo: footer.contentView.centerXAnchor),
            footerLabel.topAnchor.constraint(equalTo: footer.contentView.topAnchor, constant: 14),

            actionBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -2),
            actionBar.heightAnchor.constraint(equalToConstant: 56),
            bar.leadingAnchor.constraint(equalTo: actionBar.leadingAnchor, constant: 24),
            bar.trailingAnchor.constraint(equalTo: actionBar.trailingAnchor, constant: -24),
            bar.centerYAnchor.constraint(equalTo: actionBar.centerYAnchor)
        ])
    }

    private func buildGrid() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        let side = floor((UIScreen.main.bounds.width - 6) / 4)
        layout.itemSize = CGSize(width: side, height: side)
        layout.sectionInset = .zero
        // Fix: the count of photos and videos was pinned to the bottom of the screen; WhatsApp's is
        // the grid's own last line, under the last pictures, and scrolls with them.
        layout.footerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: 64)
        grid = UICollectionView(frame: .zero, collectionViewLayout: layout)
        grid.backgroundColor = .systemBackground
        grid.dataSource = self
        grid.delegate = self
        // The inset is measured from the chrome, which already sits below the safe area. Left on
        // automatic, UIKit adds the safe area to it a second time - which is the 65pt of empty
        // black that kept appearing above the search field however the inset was worked out.
        grid.contentInsetAdjustmentBehavior = .never
        grid.register(MediaTileCell.self, forCellWithReuseIdentifier: "tile")
        grid.register(GridCountFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                      withReuseIdentifier: "count")
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
        list.backgroundColor = .systemBackground
        list.separatorStyle = .none
        list.sectionHeaderTopPadding = 0
        list.keyboardDismissMode = .onDrag
        list.register(AttachmentRowCell.self, forCellReuseIdentifier: "row")
        list.register(LinkCardCell.self, forCellReuseIdentifier: "link")
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
        monthPillHide?.cancel()
        monthPill.alpha = 0
        list.isHidden = next == .media


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
        setTop(header.frame.maxY + 8, on: grid, bottom: view.safeAreaInsets.bottom + (isSelecting ? 64 : 0))
        setTop(header.frame.maxY + 11, on: list, bottom: view.safeAreaInsets.bottom + (isSelecting ? 76 : 24))

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
        guard top > 0, abs(scroller.contentInset.top - top) > 0.5 || abs(scroller.contentInset.bottom - bottom) > 0.5 else {
            return
        }
        // A list sitting at its top should stay there rather than be left showing a gap where the
        // inset used to be.
        let wasAtTop = abs(scroller.contentInset.top - top) > 0.5 && scroller.contentOffset.y <= -scroller.contentInset.top + 1
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
            shownLinks = needle.isEmpty ? links : links.filter { item in
                if item.url.lowercased().contains(needle) || LinkCardCell.caption(of: item).lowercased().contains(needle) {
                    return true
                }
                // What the card shows of the page is searched too, as WhatsApp searches it.
                guard let facts = storedFacts(for: item) else {
                    return false
                }
                return facts.title.lowercased().contains(needle) || facts.blurb.lowercased().contains(needle)
                    || facts.domain.contains(needle)
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
        refreshSelectionChrome(animated: true)
        // The rows on screen slide over to make room for the circles, rather than being rebuilt in
        // one jump - WhatsApp's way. The rest pick the state up as they are drawn.
        if currentTab == .media {
            grid.reloadData()
        } else {
            for cell in list.visibleCells {
                (cell as? AttachmentRowCell)?.setSelecting(isSelecting, picked: false, animated: true)
                (cell as? LinkCardCell)?.setSelecting(isSelecting, picked: false, animated: true)
            }
        }
    }

    /// One spring for everything that moves when choosing starts or ends, so the header, the rows
    /// and the bar move as one.
    static func selectionMotion(_ changes: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.38, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0,
                       options: [.beginFromCurrentState, .allowUserInteraction], animations: changes, completion: completion)
    }

    /// Keeps the button hugging its own words, whichever of the two it is showing.
    /// "Select", and while choosing a round X on the same glass - WhatsApp's Cancel.
    private func applySelectTitle() {
        var style = UIButton.Configuration.plain()
        if isSelecting {
            style.image = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
            style.contentInsets = .zero
        } else {
            style.attributedTitle = AttributedString("Select".localized(),
                                                     attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 15),
                                                                                     .foregroundColor: UIColor.label]))
            style.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14)
        }
        selectButton.configuration = style
        selectButton.tintColor = .label
        selectButton.accessibilityLabel = isSelecting ? "Cancel".localized() : "Select".localized()
    }

    private func refreshSelectionChrome(animated: Bool = false) {
        if animated {
            UIView.transition(with: selectButton, duration: 0.25, options: [.transitionCrossDissolve, .allowUserInteraction],
                              animations: { self.applySelectTitle() })
        } else {
            applySelectTitle()
        }
        let selecting = isSelecting
        // Faded rather than snapped: the back button out, the bar in, the search field dimmed -
        // it cannot be used while choosing.
        if selecting {
            searchBar.resignFirstResponder()
        }
        searchBar.isUserInteractionEnabled = !selecting
        let showBack = !selecting
        let showBar = selecting
        if animated {
            if showBack {
                backButton.isHidden = false
                backGlass?.isHidden = false
            }
            if showBar {
                actionBar.isHidden = false
            }
        } else {
            backButton.isHidden = !showBack
            backGlass?.isHidden = !showBack
            actionBar.isHidden = !showBar
        }
        selectSquare?.isActive = isSelecting
        if isSelecting {
            segmentsBesideBack?.isActive = false
            segmentsCentred?.isActive = true
        } else {
            segmentsCentred?.isActive = false
            segmentsBesideBack?.isActive = true
        }

        actionBar.isHidden = !isSelecting
        forwardHolder?.isHidden = currentTab == .media
        let chosen = pickedItems()
        let any = !chosen.ids.isEmpty
        forwardButton.isEnabled = any && onForward != nil
        starButton.isEnabled = any && onStar != nil
        shareButton.isEnabled = any && chosen.shareable
        deleteButton.isEnabled = any && onDelete != nil
        deleteButton.tintColor = deleteButton.isEnabled ? .systemRed : .label
        let allStarred = any && chosen.allStarred
        starButton.setImage(UIImage(systemName: allStarred ? "star.slash" : "star",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)), for: .normal)

        // The count is part of the grid now (GridCountFooter); the strip that carried it stays away.
        footer.isHidden = true
        let changes = {
            self.backButton.alpha = showBack ? 1 : 0
            self.backGlass?.alpha = showBack ? 1 : 0
            self.actionBar.alpha = showBar ? 1 : 0
            self.searchBar.alpha = selecting ? 0.45 : 1
            self.view.layoutIfNeeded()
        }
        if animated {
            Self.selectionMotion(changes) { _ in
                // Settled: what faded out is taken away, unless choosing was turned back meanwhile.
                guard self.isSelecting == selecting else { return }
                self.backButton.isHidden = !showBack
                self.backGlass?.isHidden = !showBack
                self.actionBar.isHidden = !showBar
            }
        } else {
            UIView.performWithoutAnimation(changes)
        }
        refreshInsets()
    }

    /// What is chosen on the tab being shown: the messages, whether every one of them is starred,
    /// and whether every one may be shared.
    private func pickedItems() -> (ids: [String], allStarred: Bool, shareable: Bool) {
        switch currentTab {
        case .media:
            let items = media.filter { picked.contains($0.messageId) }
            return (items.map { $0.messageId }, items.allSatisfy { $0.isStarred }, items.allSatisfy { $0.canShare })
        case .links:
            let items = links.filter { picked.contains($0.messageId) }
            return (items.map { $0.messageId }, items.allSatisfy { $0.isStarred }, items.allSatisfy { $0.canShare })
        case .docs:
            let items = docs.filter { picked.contains($0.messageId) }
            return (items.map { $0.messageId }, items.allSatisfy { $0.isStarred }, items.allSatisfy { $0.canShare })
        }
    }

    /// Stars everything chosen - or, when all of it already is, unstars it, as WhatsApp does.
    @objc private func tapStarPicked() {
        guard let star = onStar else {
            return
        }
        let chosen = pickedItems()
        let target = !chosen.allStarred
        for id in chosen.ids {
            let current: Bool
            if let item = media.first(where: { $0.messageId == id }) {
                current = item.isStarred
            } else if let item = links.first(where: { $0.messageId == id }) {
                current = item.isStarred
            } else {
                current = docs.first(where: { $0.messageId == id })?.isStarred ?? false
            }
            if current != target {
                star(id)
                setStarred(target, messageId: id)
            }
        }
        view.presentToast((target ? "Starred" : "Unstarred").localized())
        isSelecting = false
        picked.removeAll()
        refreshSelectionChrome()
        reloadCurrent()
    }

    /// The share sheet for everything chosen: the files of pictures, videos and documents (those
    /// on the device), or the addresses of links.
    @objc private func tapSharePicked() {
        let chosen = pickedItems()
        guard !chosen.ids.isEmpty, chosen.shareable else {
            return
        }
        var things: [Any] = []
        switch currentTab {
        case .media:
            for item in media where picked.contains(item.messageId) {
                if let url = readableURL(storedName: item.mediaFileName, named: item.mediaFileName, kind: "") {
                    things.append(url)
                }
            }
        case .links:
            for item in links where picked.contains(item.messageId) {
                things.append(URL(string: item.url) ?? item.url)
            }
        case .docs:
            for item in docs where picked.contains(item.messageId) {
                if let url = readableURL(for: item) {
                    things.append(url)
                }
            }
        }
        guard !things.isEmpty else {
            view.presentToast("Download the files first to share them.".localized())
            return
        }
        let sheet = UIActivityViewController(activityItems: things, applicationActivities: nil)
        sheet.popoverPresentationController?.sourceView = shareButton
        sheet.popoverPresentationController?.sourceRect = shareButton.bounds
        present(sheet, animated: true)
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
        return OfficePreview.item(previewURL!)
    }
}

extension MediaBrowserViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "count", for: indexPath)
        (footer as? GridCountFooter)?.label.text = mediaSummary()
        return footer
    }

    // MARK: Month beside the scroll indicator

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === grid, scrollView.isDragging || scrollView.isDecelerating else {
            return
        }
        placeMonthPill()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView === grid, !decelerate {
            hideMonthPillSoon()
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView === grid {
            hideMonthPillSoon()
        }
    }

    /// Puts the month beside where the scroll indicator is, naming the pictures level with it.
    private func placeMonthPill() {
        let insets = grid.adjustedContentInset
        let visible = grid.bounds.height - insets.top - insets.bottom
        let travel = grid.contentSize.height - visible
        guard visible > 0, travel > 40, !media.isEmpty else {
            return
        }
        let progress = min(1, max(0, (grid.contentOffset.y + insets.top) / travel))
        let pillHeight: CGFloat = 28
        let top = grid.frame.minY + insets.top + 6
        let bottom = grid.frame.minY + insets.top + visible - pillHeight - 6
        let y = top + (bottom - top) * progress

        // The pictures level with the pill, in the grid's own coordinates.
        let level = grid.contentOffset.y + (y - grid.frame.minY) + pillHeight / 2
        var found: IndexPath?
        for x in stride(from: grid.bounds.width - 10, through: 10, by: -grid.bounds.width / 4) {
            if let indexPath = grid.indexPathForItem(at: CGPoint(x: x, y: level)) {
                found = indexPath
                break
            }
        }
        if found == nil {
            found = grid.indexPathsForVisibleItems.min(by: {
                abs((grid.layoutAttributesForItem(at: $0)?.frame.midY ?? 0) - level)
                    < abs((grid.layoutAttributesForItem(at: $1)?.frame.midY ?? 0) - level)
            })
        }
        guard let item = found?.item, item < media.count, media[item].date > 0 else {
            return
        }
        let stamp = Date(timeIntervalSince1970: media[item].date / 1000)
        monthPillLabel.text = DateFormatterPool.shared.string(from: stamp, format: "MMM yyyy")
        let width = ceil(monthPillLabel.intrinsicContentSize.width) + 24
        monthPill.frame = CGRect(x: view.bounds.width - width - 14, y: y, width: width, height: pillHeight)
        monthPillHide?.cancel()
        if monthPill.alpha < 1 {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
                self.monthPill.alpha = 1
            }
        }
    }

    private func hideMonthPillSoon() {
        monthPillHide?.cancel()
        let hide = DispatchWorkItem { [weak self] in
            UIView.animate(withDuration: 0.35, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
                self?.monthPill.alpha = 0
            }
        }
        monthPillHide = hide
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: hide)
    }

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
        let all = media.map { item in
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
        // What has not been downloaded yet is not in the viewer - see downloadedOnly.
        let openedId = media[index].messageId
        viewer.stripItems = MediaViewerViewController.downloadedOnly(all, keeping: openedId)
        viewer.currentStripIndex = viewer.stripItems.firstIndex(where: { $0.messageId == openedId }) ?? 0
        let stripIndex = viewer.currentStripIndex
        if let ready = MediaViewerViewController.loadMedia(for: viewer.stripItems[stripIndex]) {
            viewer.media = ready
            viewer.autoPlaysOnOpen = viewer.stripItems[stripIndex].isVideo
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
            // The grid is moved to whichever picture the reader ended on before its square is
            // asked for - see focus(on:). Without that the square is often off screen, and a
            // square off screen is either nothing to aim at or somewhere the reader cannot see.
            self.focus(on: viewer.currentMessageId)
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
        strip.backgroundColor = BrowserPalette.monthStrip
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
        let index = sections[indexPath.section].rows[indexPath.row]
        if currentTab == .docs {
            let cell = tableView.dequeueReusableCell(withIdentifier: "row", for: indexPath) as! AttachmentRowCell
            let doc = shownDocs[index]
            let line = docLine(for: doc)
            cell.showDoc(doc, line: line.text, downloadFraction: line.fraction, isHere: line.isHere,
                         selecting: isSelecting, picked: picked.contains(doc.messageId))
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "link", for: indexPath) as! LinkCardCell
        let link = shownLinks[index]
        cell.onViewMessage = onGoToMessage == nil ? nil : { [weak self] in
            self?.onGoToMessage?(link.messageId)
        }
        cell.show(link, facts: pageFacts(for: link), query: searchText.trimmingCharacters(in: .whitespaces),
                  selecting: isSelecting, picked: picked.contains(link.messageId))
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
            let doc = shownDocs[index]
            if isHere(doc) {
                open(doc)
            } else if docDownloads[doc.messageId] == nil {
                // Not on the device yet: fetched here, the row counting up as it comes, and opened
                // the moment it is in - as WhatsApp does.
                downloadDoc(doc) { [weak self] in
                    guard let self = self, self.viewIfLoaded?.window != nil, self.presentedViewController == nil else {
                        return
                    }
                    self.open(doc)
                }
            }
        } else {
            openLink(shownLinks[index])
        }
    }

    // MARK: - Links

    /// Opens a link exactly as tapping it in the conversation does (LinkOpener): a well-known
    /// app's link straight into that app, anything else in the secure browser where the
    /// secure_browser access is on, and in Safari otherwise.
    ///
    /// Fix: this handed every link to Safari, past the secure browser the conversation keeps
    /// them in.
    private func openLink(_ item: LinkItem) {
        LinkOpener.open(urlString: item.previewKey)
    }

    /// What is known of the page behind a link - its title and picture, as the conversation's
    /// card shows them. A page never read before is read once, and its rows redrawn when it is in.
    private func pageFacts(for item: LinkItem) -> LinkPreviewFacts? {
        let key = item.previewKey
        let answer: LinkPreviewStore.Answer
        if let known = linkAnswers[key] {
            answer = known
        } else {
            answer = LinkPreviewStore.answer(link: key)
            linkAnswers[key] = answer
        }
        switch answer {
        case .read(let facts):
            return facts
        case .nothingOnIt:
            return nil
        case .notAsked:
            if askedLinkPages.insert(key).inserted {
                LinkPreviewFetcher.fetch(link: key) { [weak self] gained in
                    guard let self = self, gained else { return }
                    self.linkAnswers[key] = nil
                    self.refreshLinkRows(previewKey: key)
                }
            }
            return nil
        }
    }

    /// What the device already holds about a link's page, without asking the network.
    private func storedFacts(for item: LinkItem) -> LinkPreviewFacts? {
        let key = item.previewKey
        if linkAnswers[key] == nil {
            linkAnswers[key] = LinkPreviewStore.answer(link: key)
        }
        if case .read(let facts) = linkAnswers[key] {
            return facts
        }
        return nil
    }

    /// Redraws the visible rows of one link once its page has been read.
    private func refreshLinkRows(previewKey: String) {
        guard currentTab == .links else {
            return
        }
        var rows: [IndexPath] = []
        for indexPath in list.indexPathsForVisibleRows ?? [] {
            guard indexPath.section < sections.count, indexPath.row < sections[indexPath.section].rows.count else {
                continue
            }
            let index = sections[indexPath.section].rows[indexPath.row]
            if index < shownLinks.count, shownLinks[index].previewKey == previewKey {
                rows.append(indexPath)
            }
        }
        if !rows.isEmpty {
            list.reloadRows(at: rows, with: .none)
        }
    }

    private func shareLink(_ item: LinkItem) {
        let shared: Any = URL(string: item.url) ?? item.url
        let sheet = UIActivityViewController(activityItems: [shared], applicationActivities: nil)
        sheet.popoverPresentationController?.sourceView = view
        sheet.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        present(sheet, animated: true)
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
        if let url = readableURL(for: item) {
            preview(url)
            return
        }
        if !isHere(item) {
            onGoToMessage?(item.messageId)
        }
    }

    /// A file Quick Look, the share sheet or a preview can read: the plain copy where there is
    /// one, otherwise the secure copy decrypted into caches. Nil when the file is not here.
    private func readableURL(for item: DocItem) -> URL? {
        return readableURL(storedName: item.storedName, named: item.fileName, kind: item.kind)
    }

    private func readableURL(storedName: String, named fileName: String, kind: String) -> URL? {
        guard !storedName.isEmpty else {
            return nil
        }
        let plain = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
            .appendingPathComponent(storedName)
        if FileManager.default.fileExists(atPath: plain.path) {
            return plain
        }
        guard FileEncryption.shared.isSecureExists(filename: storedName),
              var data = try? FileEncryption.shared.readSecure(filename: storedName) else {
            return nil
        }
        if let plainData = FileEncryption.shared.decryptFileFromServer(data: data) {
            data = plainData
        }
        // Quick Look reads from disk, and what is in the secure store cannot be handed to it as it
        // stands, so a readable copy is left in caches for it - under the name the reader knows.
        let folder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("docs-open", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var named = (fileName as NSString).lastPathComponent
        if named.isEmpty {
            named = storedName
        }
        // Quick Look decides how to draw a file by its extension, so a name that does not carry one
        // gets the kind the file itself says it is.
        if Utils.documentExtension(of: named).isEmpty, !kind.isEmpty {
            named += "." + kind
        }
        let temporary = folder.appendingPathComponent(named)
        guard (try? data.write(to: temporary, options: .atomic)) != nil else {
            return nil
        }
        return temporary
    }

    // MARK: - Documents: what is known about them, and fetching them

    private func isHere(_ item: DocItem) -> Bool {
        return PDFBubblePreview.isHere(fileNamed: item.storedName)
    }

    /// The line under a document's name, WhatsApp's way:
    /// - here: "8 pages · 134 KB · pdf" (pages for a PDF only, once counted);
    /// - not yet fetched: its size, with an arrow beside it in the cell;
    /// - downloading: how much has come and how much there is, and the percentage.
    private func docLine(for item: DocItem) -> (text: String, fraction: Double?, isHere: Bool) {
        let kind = item.kind
        if let percent = docDownloads[item.messageId] {
            var text = "\(Int(percent))%"
            if let bytes = TransferBytes.get(name: item.storedName), bytes.total > 0 {
                text = VideoNote.Facts.humanSize(bytes.completed) + " / " + VideoNote.Facts.humanSize(bytes.total) + " · " + text
            }
            return (text, max(0, min(1, percent / 100)), false)
        }
        let here = isHere(item)
        askDocFacts(for: item, here: here)
        var parts: [String] = []
        if here, let pages = docPages[item.storedName], pages > 0 {
            parts.append(pages == 1 ? "1 page".localized() : String(format: "%d pages".localized(), pages))
        }
        if let size = docSizes[item.storedName], size > 0 {
            parts.append(VideoNote.Facts.humanSize(size))
        }
        if here, !kind.isEmpty {
            parts.append(kind)
        }
        return (parts.joined(separator: " · "), nil, here)
    }

    /// Finds out once what a row says about its file: the size (the sender's figure, else the
    /// server's), and a PDF's page count once it is on the device. The row redraws its line as
    /// each answer arrives.
    private func askDocFacts(for item: DocItem, here: Bool) {
        let name = item.storedName
        guard !name.isEmpty, askedDocFacts.insert(name + (here ? "#here" : "#away")).inserted else {
            return
        }
        if docSizes[name] == nil {
            let known = VideoNote.Facts.expectedSize(ofAttachmentNamed: name)
            if known > 0 {
                docSizes[name] = known
            } else {
                Download.remoteSize(forKey: name) { [weak self] answer in
                    guard let self = self, answer > 0 else { return }
                    self.docSizes[name] = answer
                    self.refreshDocRows(storedName: name)
                }
            }
        }
        if here, item.kind == "pdf", docPages[name] == nil {
            PDFBubblePreview.facts(ofFileNamed: name) { [weak self] _, pages in
                guard let self = self, pages > 0 else { return }
                self.docPages[name] = pages
                self.refreshDocRows(storedName: name)
            }
        }
    }

    /// Redraws the line of every visible row for one file, without reloading the rows.
    private func refreshDocRows(storedName: String) {
        guard currentTab == .docs else {
            return
        }
        for indexPath in list.indexPathsForVisibleRows ?? [] {
            guard indexPath.section < sections.count, indexPath.row < sections[indexPath.section].rows.count else {
                continue
            }
            let index = sections[indexPath.section].rows[indexPath.row]
            guard index < shownDocs.count, shownDocs[index].storedName == storedName,
                  let cell = list.cellForRow(at: indexPath) as? AttachmentRowCell else {
                continue
            }
            let line = docLine(for: shownDocs[index])
            cell.setLine(line.text, downloadFraction: line.fraction, isHere: line.isHere)
        }
    }

    /// Fetches a document, counting up in its row, and runs `done` once it is on the device.
    private func downloadDoc(_ item: DocItem, then done: (() -> Void)? = nil) {
        guard !item.storedName.isEmpty, docDownloads[item.messageId] == nil else {
            return
        }
        docDownloads[item.messageId] = 0
        refreshDocRows(storedName: item.storedName)
        Download().startHTTP(forKey: item.storedName) { [weak self] _, progress in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if progress < 0 {
                    self.docDownloads[item.messageId] = nil
                    self.refreshDocRows(storedName: item.storedName)
                    self.view.presentToast("Download failed. Please try again.".localized())
                    return
                }
                if progress >= 100 {
                    self.docDownloads[item.messageId] = nil
                    TransferBytes.clear(name: item.storedName)
                    self.refreshDocRows(storedName: item.storedName)
                    done?()
                    return
                }
                self.docDownloads[item.messageId] = progress
                self.refreshDocRows(storedName: item.storedName)
            }
        }
    }

    /// The share sheet for a document - fetched first if it is not here yet.
    private func shareDoc(_ item: DocItem) {
        guard isHere(item) else {
            downloadDoc(item) { [weak self] in self?.shareDoc(item) }
            return
        }
        guard let url = readableURL(for: item) else {
            return
        }
        let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        sheet.popoverPresentationController?.sourceView = view
        sheet.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        present(sheet, animated: true)
    }

    /// Marks a document or a link starred or not in every list, after the conversation has been
    /// asked to.
    private func setStarred(_ starred: Bool, messageId: String) {
        if let index = docs.firstIndex(where: { $0.messageId == messageId }) {
            docs[index].isStarred = starred
        }
        if let index = shownDocs.firstIndex(where: { $0.messageId == messageId }) {
            shownDocs[index].isStarred = starred
        }
        if let index = links.firstIndex(where: { $0.messageId == messageId }) {
            links[index].isStarred = starred
        }
        if let index = shownLinks.firstIndex(where: { $0.messageId == messageId }) {
            shownLinks[index].isStarred = starred
        }
        if let index = media.firstIndex(where: { $0.messageId == messageId }) {
            media[index].isStarred = starred
        }
    }

    private func preview(_ url: URL) {
        previewURL = url as NSURL
        let quickLook = QLPreviewController()
        quickLook.dataSource = self
        present(quickLook, animated: true)
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // A link card is as tall as what it says - title, description, site, and the message's
        // own words under them.
        return currentTab == .links ? UITableView.automaticDimension : 74
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return currentTab == .links ? 150 : 74
    }

    /// Holding a document, as in WhatsApp: a look at what is in it above Go to message, Star, Share
    /// and Delete - and, for a file still to be fetched, Download first and no look, since there is
    /// nothing yet to look at.
    public func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath,
                          point: CGPoint) -> UIContextMenuConfiguration? {
        guard currentTab != .media, !isSelecting, indexPath.section < sections.count,
              indexPath.row < sections[indexPath.section].rows.count else {
            return nil
        }
        let index = sections[indexPath.section].rows[indexPath.row]
        if currentTab == .links {
            return index < shownLinks.count ? linkMenu(for: shownLinks[index]) : nil
        }
        guard index < shownDocs.count else {
            return nil
        }
        let item = shownDocs[index]
        let here = isHere(item)
        let preview: UIContextMenuContentPreviewProvider? = here ? { [weak self] in
            guard let self = self else { return nil }
            return DocPreviewController(url: self.readableURL(for: item), title: item.fileName, kind: item.kind)
        } : nil
        return UIContextMenuConfiguration(identifier: item.messageId as NSString, previewProvider: preview) { [weak self] _ in
            guard let self = self else { return nil }
            var actions: [UIMenuElement] = []
            if !here {
                actions.append(UIAction(title: "Download".localized(), image: UIImage(systemName: "arrow.down.circle")) { [weak self] _ in
                    self?.downloadDoc(item)
                })
            }
            if let goTo = self.onGoToMessage {
                actions.append(UIAction(title: "Go to Message".localized(), image: UIImage(systemName: "bubble.left")) { _ in
                    goTo(item.messageId)
                })
            }
            if let star = self.onStar {
                let starred = self.docs.first(where: { $0.messageId == item.messageId })?.isStarred ?? item.isStarred
                actions.append(UIAction(title: (starred ? "Unstar" : "Star").localized(),
                                        image: UIImage(systemName: starred ? "star.slash" : "star")) { [weak self] _ in
                    star(item.messageId)
                    self?.setStarred(!starred, messageId: item.messageId)
                })
            }
            if item.canShare {
                actions.append(UIAction(title: "Share".localized(), image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                    self?.shareDoc(item)
                })
            }
            if let delete = self.onDelete {
                actions.append(UIAction(title: "Delete".localized(), image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                    delete([item.messageId])
                })
            }
            return UIMenu(title: "", children: actions)
        }
    }

    /// Holding a link, as in WhatsApp: the page itself above Open link, Go to message, Star, Share
    /// and Delete. WhatsApp's Add to Reading List is left out - there is no reading list here.
    private func linkMenu(for item: LinkItem) -> UIContextMenuConfiguration {
        let preview: UIContextMenuContentPreviewProvider? = URL(string: item.url).map { url in
            { LinkPagePreviewController(url: url) }
        }
        return UIContextMenuConfiguration(identifier: ("link:" + item.messageId) as NSString, previewProvider: preview) { [weak self] _ in
            guard let self = self else { return nil }
            var actions: [UIMenuElement] = [
                UIAction(title: "Open link".localized(), image: UIImage(systemName: "safari")) { [weak self] _ in
                    self?.openLink(item)
                }
            ]
            if let goTo = self.onGoToMessage {
                actions.append(UIAction(title: "Go to Message".localized(), image: UIImage(systemName: "bubble.left")) { _ in
                    goTo(item.messageId)
                })
            }
            if let star = self.onStar {
                let starred = self.links.first(where: { $0.messageId == item.messageId })?.isStarred ?? item.isStarred
                actions.append(UIAction(title: (starred ? "Unstar" : "Star").localized(),
                                        image: UIImage(systemName: starred ? "star.slash" : "star")) { [weak self] _ in
                    star(item.messageId)
                    self?.setStarred(!starred, messageId: item.messageId)
                })
            }
            if item.canShare {
                actions.append(UIAction(title: "Share".localized(), image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                    self?.shareLink(item)
                })
            }
            if let delete = self.onDelete {
                actions.append(UIAction(title: "Delete".localized(), image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                    delete([item.messageId])
                })
            }
            return UIMenu(title: "", children: actions)
        }
    }

    /// Tapping the look opens what was held: the document, or the link.
    public func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
                          animator: UIContextMenuInteractionCommitAnimating) {
        guard let identifier = configuration.identifier as? String else {
            return
        }
        if identifier.hasPrefix("link:") {
            let messageId = String(identifier.dropFirst(5))
            guard let item = shownLinks.first(where: { $0.messageId == messageId }) else {
                return
            }
            animator.addCompletion { [weak self] in
                self?.openLink(item)
            }
            return
        }
        guard let item = shownDocs.first(where: { $0.messageId == identifier }) else {
            return
        }
        animator.addCompletion { [weak self] in
            self?.open(item)
        }
    }
}

/// The look at a link a held row shows, as WhatsApp's: the page itself, loaded live, under a thin
/// strip with the site's address.
final class LinkPagePreviewController: UIViewController, WKNavigationDelegate {

    private let url: URL
    private let web = WKWebView(frame: .zero, configuration: {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        configuration.websiteDataStore = .nonPersistent()
        return configuration
    }())
    private let spinner = UIActivityIndicatorView(style: .medium)

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
        let screen = UIScreen.main.bounds.size
        let width = min(screen.width - 32, 420)
        preferredContentSize = CGSize(width: width, height: min(width * 1.45, screen.height * 0.6))
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground

        let address = UILabel()
        var host = url.host ?? url.absoluteString
        if host.lowercased().hasPrefix("www.") {
            host = String(host.dropFirst(4))
        }
        address.text = host
        address.font = .systemFont(ofSize: 12)
        address.textColor = .secondaryLabel
        address.textAlignment = .center
        address.lineBreakMode = .byTruncatingMiddle
        address.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(address)

        web.navigationDelegate = self
        web.isOpaque = false
        web.backgroundColor = .secondarySystemBackground
        web.scrollView.isScrollEnabled = false
        web.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(web)

        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            address.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            address.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            address.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            address.heightAnchor.constraint(equalToConstant: 16),
            web.topAnchor.constraint(equalTo: address.bottomAnchor, constant: 6),
            web.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            web.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            web.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: web.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: web.centerYAnchor)
        ])
        web.load(URLRequest(url: url))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        spinner.stopAnimating()
        spinner.isHidden = true
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        spinner.stopAnimating()
        spinner.isHidden = true
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        spinner.stopAnimating()
        spinner.isHidden = true
    }

    /// Only a look: a page that wants to take the reader to an app or a store from inside the
    /// preview stays where it is.
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let scheme = navigationAction.request.url?.scheme?.lowercased() ?? ""
        decisionHandler(scheme == "http" || scheme == "https" || scheme == "about" || scheme == "blob" || scheme == "data" ? .allow : .cancel)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        web.stopLoading()
    }
}

/// The look at a document a held row shows: its name across the top, and under it the pages of a
/// PDF to scroll through, the text of a text file, or the first page of anything else Quick Look
/// can draw.
final class DocPreviewController: UIViewController {

    private let url: URL?
    private let fileTitle: String
    private let kind: String

    init(url: URL?, title: String, kind: String) {
        self.url = url
        self.fileTitle = title
        self.kind = kind
        super.init(nibName: nil, bundle: nil)
        let width = min(UIScreen.main.bounds.width - 32, 420)
        preferredContentSize = CGSize(width: width, height: width * 1.25)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground

        let titleLabel = UILabel()
        titleLabel.text = fileTitle
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byTruncatingMiddle
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        let body = makeBody()
        body.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(body)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            body.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            body.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            body.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private static let textKinds: Set<String> = ["txt", "md", "log", "json", "xml", "csv", "yml", "yaml", "html", "htm"]

    private func makeBody() -> UIView {
        guard let url = url else {
            return UIView()
        }
        let kind = self.kind.isEmpty ? url.pathExtension.lowercased() : self.kind
        if kind == "pdf", let document = PDFDocument(url: url) {
            let pdf = PDFView()
            pdf.document = document
            pdf.autoScales = true
            pdf.displayMode = .singlePageContinuous
            pdf.backgroundColor = .secondarySystemBackground
            return pdf
        }
        if DocPreviewController.textKinds.contains(kind), let text = try? String(contentsOf: url, encoding: .utf8) {
            let textView = UITextView()
            textView.isEditable = false
            textView.backgroundColor = .systemBackground
            textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
            textView.text = String(text.prefix(20_000))
            textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
            return textView
        }
        // Anything else: the first page, drawn by Quick Look.
        let picture = UIImageView()
        picture.contentMode = .scaleAspectFit
        picture.backgroundColor = .systemBackground
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        picture.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: picture.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: picture.centerYAnchor)
        ])
        let size = preferredContentSize
        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: UIScreen.main.scale,
                                                   representationTypes: .thumbnail)
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { [weak picture, weak spinner] representation, _ in
            DispatchQueue.main.async {
                spinner?.removeFromSuperview()
                picture?.image = representation?.uiImage ?? UIImage(systemName: "doc")
            }
        }
        return picture
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

/// The count of photos and videos as the last line of the Media grid.
final class GridCountFooter: UICollectionReusableView {

    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .systemFont(ofSize: 17)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        return nil
    }
}

/// The media browser's colours, light and dark, as WhatsApp's Media / Links / Docs screen has
/// them: white with pale grey month strips and cards in light mode, black with dark grey ones in
/// dark mode.
enum BrowserPalette {

    private static func pair(light: CGFloat, dark: CGFloat) -> UIColor {
        return UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: dark, alpha: 1) : UIColor(white: light, alpha: 1) }
    }

    static let monthStrip = pair(light: 0.95, dark: 0.10)
    static let cardTop = pair(light: 0.95, dark: 0.19)
    static let cardFoot = pair(light: 1.0, dark: 0.12)
    static let cardEdge = pair(light: 0.88, dark: 0.26)
    static let pictureWell = pair(light: 0.90, dark: 0.25)
    static let compassDisc = pair(light: 0.62, dark: 0.36)
    static let compassGlyph = pair(light: 0.95, dark: 0.62)
    static let pageSheet = pair(light: 0.92, dark: 0.24)
    static let pageEdge = pair(light: 0.84, dark: 0.32)
    static let pageFold = pair(light: 0.80, dark: 0.40)
    static let plainTag = pair(light: 0.62, dark: 0.36)
    static let plainTagText = pair(light: 1.0, dark: 0.72)
    static let selectedSegment = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.22) : UIColor(white: 0, alpha: 0.08)
    }
    /// What marks a searched word: a muted olive in dark mode, a soft yellow in light.
    static let searchMark = UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.62, green: 0.56, blue: 0.22, alpha: 0.75)
            : UIColor(red: 1.0, green: 0.86, blue: 0.35, alpha: 0.7)
    }
}

/// One row of the Links list, as WhatsApp draws it: a card with the page's picture - or a compass
/// where there is none - beside its title, description and site, and under it what the link was
/// sent with (two lines at most), or "View message" when it was sent alone; either goes to the
/// message. The card
/// itself opens the link. While searching, what was searched for is marked wherever it shows.
final class LinkCardCell: UITableViewCell {

    var onViewMessage: (() -> Void)?

    private let card = UIView()
    private let top = UIView()
    private let picture = UIImageView()
    private let compass = UIImageView(image: UIImage(systemName: "safari", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)))
    private let playMark = UIImageView(image: UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)))
    private let title = UILabel()
    private let blurb = UILabel()
    private let site = UILabel()
    private let footer = UIButton(type: .custom)
    private let footerLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)))
    private let tick = UIImageView()
    private var cardLeading: NSLayoutConstraint!
    /// The picture this row was last asked for, so one arriving after the row was reused is dropped.
    private var pictureAddress = ""

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        card.backgroundColor = BrowserPalette.cardFoot
        card.layer.cornerRadius = 4
        card.layer.borderWidth = 1 / UIScreen.main.scale
        card.layer.borderColor = BrowserPalette.cardEdge.resolvedColor(with: traitCollection).cgColor
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        top.backgroundColor = BrowserPalette.cardTop
        top.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(top)

        picture.backgroundColor = BrowserPalette.pictureWell
        picture.contentMode = .scaleAspectFill
        picture.clipsToBounds = true
        // Fix: an image view asks to be as big as its picture, and a page's picture is often a
        // full-size screenshot - a Google Docs page or a Zoom banner stretched the card to the
        // height of the screen. The square is set by the card, never by what is in it.
        for axis in [NSLayoutConstraint.Axis.horizontal, .vertical] {
            picture.setContentHuggingPriority(.defaultLow, for: axis)
            picture.setContentCompressionResistancePriority(UILayoutPriority(1), for: axis)
        }
        picture.translatesAutoresizingMaskIntoConstraints = false
        top.addSubview(picture)

        compass.tintColor = BrowserPalette.compassGlyph
        compass.contentMode = .center
        compass.backgroundColor = BrowserPalette.compassDisc
        compass.layer.cornerRadius = 20
        compass.clipsToBounds = true
        compass.translatesAutoresizingMaskIntoConstraints = false
        picture.addSubview(compass)

        playMark.tintColor = .white
        playMark.contentMode = .center
        playMark.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        playMark.layer.cornerRadius = 14
        playMark.clipsToBounds = true
        playMark.translatesAutoresizingMaskIntoConstraints = false
        picture.addSubview(playMark)

        title.font = .systemFont(ofSize: 15)
        title.textColor = .label
        title.numberOfLines = 2
        title.lineBreakMode = .byCharWrapping
        blurb.font = .systemFont(ofSize: 14)
        blurb.textColor = .secondaryLabel
        blurb.numberOfLines = 2
        site.font = .systemFont(ofSize: 14)
        site.textColor = .secondaryLabel
        site.numberOfLines = 1
        let words = UIStackView(arrangedSubviews: [title, blurb, site])
        words.axis = .vertical
        words.spacing = 2
        words.translatesAutoresizingMaskIntoConstraints = false
        top.addSubview(words)

        footer.translatesAutoresizingMaskIntoConstraints = false
        footer.addTarget(self, action: #selector(viewMessageTapped), for: .touchUpInside)
        card.addSubview(footer)
        footerLabel.text = "View message".localized()
        footerLabel.font = .systemFont(ofSize: 15)
        footerLabel.textColor = .secondaryLabel
        footerLabel.numberOfLines = 2
        footerLabel.isUserInteractionEnabled = false
        footerLabel.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(footerLabel)
        chevron.tintColor = .tertiaryLabel
        chevron.isUserInteractionEnabled = false
        chevron.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(chevron)

        tick.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tick)

        cardLeading = card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        NSLayoutConstraint.activate([
            cardLeading,
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            top.topAnchor.constraint(equalTo: card.topAnchor),
            top.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            top.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            top.heightAnchor.constraint(greaterThanOrEqualToConstant: 72),

            picture.leadingAnchor.constraint(equalTo: top.leadingAnchor),
            picture.topAnchor.constraint(equalTo: top.topAnchor),
            picture.bottomAnchor.constraint(equalTo: top.bottomAnchor),
            picture.widthAnchor.constraint(equalToConstant: 72),

            compass.centerXAnchor.constraint(equalTo: picture.centerXAnchor),
            compass.centerYAnchor.constraint(equalTo: picture.centerYAnchor),
            compass.widthAnchor.constraint(equalToConstant: 40),
            compass.heightAnchor.constraint(equalToConstant: 40),

            playMark.centerXAnchor.constraint(equalTo: picture.centerXAnchor),
            playMark.centerYAnchor.constraint(equalTo: picture.centerYAnchor),
            playMark.widthAnchor.constraint(equalToConstant: 28),
            playMark.heightAnchor.constraint(equalToConstant: 28),

            words.leadingAnchor.constraint(equalTo: picture.trailingAnchor, constant: 12),
            words.trailingAnchor.constraint(equalTo: top.trailingAnchor, constant: -12),
            words.centerYAnchor.constraint(equalTo: top.centerYAnchor),
            words.topAnchor.constraint(greaterThanOrEqualTo: top.topAnchor, constant: 10),
            words.bottomAnchor.constraint(lessThanOrEqualTo: top.bottomAnchor, constant: -10),

            footer.topAnchor.constraint(equalTo: top.bottomAnchor),
            footer.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            footerLabel.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: 12),
            footerLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -10),
            footerLabel.topAnchor.constraint(equalTo: footer.topAnchor, constant: 10),
            footerLabel.bottomAnchor.constraint(equalTo: footer.bottomAnchor, constant: -10),
            footer.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
            chevron.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -12),
            chevron.centerYAnchor.constraint(equalTo: footer.centerYAnchor),

            tick.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            tick.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            tick.widthAnchor.constraint(equalToConstant: 22),
            tick.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        pictureAddress = ""
        picture.image = nil
        onViewMessage = nil
    }

    /// The page's title where it was read, else the address itself; the site under it; and its
    /// picture where it has one - the message's own thumbnail standing in until then.
    func show(_ item: MediaBrowserViewController.LinkItem, facts: LinkPreviewFacts?, query: String,
              selecting: Bool, picked: Bool) {
        let heading = facts?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        title.attributedText = Self.marked(heading.isEmpty ? item.url : heading, query: query, label: title)
        title.lineBreakMode = heading.isEmpty ? .byCharWrapping : .byTruncatingTail
        let about = Self.oneLine(facts?.blurb ?? "")
        blurb.attributedText = Self.marked(about, query: query, label: blurb)
        blurb.isHidden = about.isEmpty
        var host = facts?.domain ?? ""
        if host.isEmpty {
            host = (URL(string: item.url)?.host ?? "").lowercased()
        }
        site.attributedText = Self.marked(host, query: query, label: site)

        // What the link was sent with, up to two lines, as WhatsApp shows it; "View message" when
        // the link was all there was. Only the words before the black square are the sender's - what
        // follows it is the app's own business (file names, markers), never shown.
        footerLabel.attributedText = nil
        let said = Self.caption(of: item)
        footerLabel.textColor = said.isEmpty ? .secondaryLabel : .label
        if said.isEmpty {
            footerLabel.attributedText = Self.marked("View message".localized(), query: "", label: footerLabel)
        } else {
            // Fix: the caption was shown as plain characters, so *bold* came out with its stars
            // and no bold. It is formatted the way the bubble formats it - bold, italic, struck
            // through, mentions as names - and what was searched for is marked on top of that.
            footerLabel.attributedText = Self.markedRich(Self.richCaption(of: item, font: footerLabel.font),
                                                         query: query)
        }

        let address = facts?.imageUrl ?? ""
        pictureAddress = address
        var shown: UIImage?
        if !address.isEmpty {
            shown = LinkPreviewImage.cached(address)
        }
        if shown == nil, !item.thumbFileName.isEmpty {
            shown = Nexilis.imageCache.object(forKey: item.thumbFileName as NSString)
        }
        setPicture(shown, isVideo: facts?.isVideo ?? false)
        if !address.isEmpty, LinkPreviewImage.cached(address) == nil {
            LinkPreviewImage.fetch(address) { [weak self] image in
                guard let self = self, self.pictureAddress == address, let image = image else { return }
                self.setPicture(image, isVideo: facts?.isVideo ?? false)
            }
        }

        setSelecting(selecting, picked: picked, animated: false)
    }

    /// Choosing turned on or off: the circle comes in from the left and the card slides over.
    func setSelecting(_ selecting: Bool, picked: Bool, animated: Bool) {
        tick.isHidden = false
        tick.image = UIImage(systemName: picked ? "checkmark.circle.fill" : "circle")
        tick.tintColor = picked ? .systemBlue : .tertiaryLabel
        cardLeading.constant = selecting ? 46 : 12
        // While picking, the whole card is one target: it picks.
        footer.isUserInteractionEnabled = !selecting && onViewMessage != nil
        let changes = {
            self.tick.alpha = selecting ? 1 : 0
            self.tick.transform = selecting ? .identity : CGAffineTransform(translationX: -24, y: 0)
            self.contentView.layoutIfNeeded()
        }
        if animated {
            MediaBrowserViewController.selectionMotion(changes)
        } else {
            UIView.performWithoutAnimation(changes)
        }
    }

    /// The sender's own words around a link: the text before the app's black square, with the link
    /// taken out of it.
    static func caption(of item: MediaBrowserViewController.LinkItem) -> String {
        var said = item.caption.components(separatedBy: "\u{25A0}").first ?? ""
        for written in [item.previewKey, item.url] where !written.isEmpty {
            said = said.replacingOccurrences(of: written, with: " ")
        }
        // Fix: a mention is stored as "@" and the person's pin, and showed here as that pin; the
        // conversation writes it as "@name", and so does this.
        return oneLine(said.mentionsAsNames())
    }

    /// The caption formatted as the conversation formats it (String.richText), in the label's size
    /// and the text colour wherever the formatting gives none.
    static func richCaption(of item: MediaBrowserViewController.LinkItem, font: UIFont?) -> NSMutableAttributedString {
        var said = item.caption.components(separatedBy: "\u{25A0}").first ?? ""
        for written in [item.previewKey, item.url] where !written.isEmpty {
            said = said.replacingOccurrences(of: written, with: " ")
        }
        let formatted = NSMutableAttributedString(attributedString: oneLine(said).richText(fontSize: font?.pointSize ?? 15))
        let whole = NSRange(location: 0, length: formatted.length)
        formatted.enumerateAttribute(.foregroundColor, in: whole) { value, range, _ in
            if value == nil {
                formatted.addAttribute(.foregroundColor, value: UIColor.label, range: range)
            }
        }
        // Two lines at most, cut at the end - a paragraph style from the formatting would
        // otherwise decide how the label wraps.
        formatted.removeAttribute(.paragraphStyle, range: whole)
        return formatted
    }

    /// Marks what was searched for in text that is already formatted, leaving its formatting be.
    private static func markedRich(_ text: NSMutableAttributedString, query: String) -> NSAttributedString {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let plain = text.string
        guard !needle.isEmpty, !plain.isEmpty else {
            return text
        }
        var searchRange = plain.startIndex..<plain.endIndex
        while let found = plain.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive], range: searchRange) {
            text.addAttributes([.backgroundColor: BrowserPalette.searchMark, .foregroundColor: UIColor.label],
                               range: NSRange(found, in: plain))
            searchRange = found.upperBound..<plain.endIndex
        }
        return text
    }

    /// Runs of space and line breaks made one space, as a two-line label shows them.
    private static func oneLine(_ text: String) -> String {
        return text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// The text in the label's own font and colour, every place it holds what was searched for
    /// marked the way WhatsApp marks it - a muted yellow behind the letters.
    private static func marked(_ text: String, query: String, label: UILabel) -> NSAttributedString {
        let font = label.font ?? .systemFont(ofSize: 15)
        let colour = label.textColor ?? .label
        let result = NSMutableAttributedString(string: text, attributes: [.font: font, .foregroundColor: colour])
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty, !text.isEmpty else {
            return result
        }
        let mark = BrowserPalette.searchMark
        var searchRange = text.startIndex..<text.endIndex
        while let found = text.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive], range: searchRange) {
            result.addAttributes([.backgroundColor: mark, .foregroundColor: UIColor.label], range: NSRange(found, in: text))
            searchRange = found.upperBound..<text.endIndex
        }
        return result
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // A layer's border is a CGColor and does not follow the mode by itself.
        card.layer.borderColor = BrowserPalette.cardEdge.resolvedColor(with: traitCollection).cgColor
    }

    private func setPicture(_ image: UIImage?, isVideo: Bool) {
        picture.image = image
        compass.isHidden = image != nil
        playMark.isHidden = image == nil || !isVideo
    }

    @objc private func viewMessageTapped() {
        onViewMessage?()
    }
}

/// One row of the Docs list.
final class AttachmentRowCell: UITableViewCell {

    private let badge = UIView()
    private let badgeLabel = UILabel()
    private let thumb = UIImageView()
    private let title = UILabel()
    private let detail = UILabel()
    private let tick = UIImageView()
    /// A document's page, the way WhatsApp draws it - see DocPageIcon.
    private let page = DocPageIcon()
    /// How far a download has got, under the line that says it.
    private let progress = UIProgressView(progressViewStyle: .bar)
    /// Where the row's icon starts: at the edge, or past the circle while choosing.
    private var badgeLeading: NSLayoutConstraint!

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

        page.translatesAutoresizingMaskIntoConstraints = false
        page.isHidden = true
        contentView.addSubview(page)

        progress.trackTintColor = .tertiarySystemFill
        progress.progressTintColor = .systemGreen
        progress.layer.cornerRadius = 1.5
        progress.clipsToBounds = true
        progress.isHidden = true
        progress.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(progress)

        // Fix: the circle for choosing was at the right-hand end of the row; WhatsApp puts it at the
        // left, before the page, and slides the row over to make room - as the Links cards do.
        badgeLeading = badge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        NSLayoutConstraint.activate([
            badgeLeading,
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
            title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            detail.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            detail.trailingAnchor.constraint(equalTo: title.trailingAnchor),
            detail.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 3),

            page.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            page.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            page.widthAnchor.constraint(equalToConstant: 38),
            page.heightAnchor.constraint(equalToConstant: 50),

            progress.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            progress.trailingAnchor.constraint(equalTo: title.trailingAnchor),
            progress.topAnchor.constraint(equalTo: detail.bottomAnchor, constant: 5),
            progress.heightAnchor.constraint(equalToConstant: 3),

            tick.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            tick.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            tick.widthAnchor.constraint(equalToConstant: 22),
            tick.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    required init?(coder: NSCoder) {
        return nil
    }

    /// A document row, as WhatsApp draws one: its page with the extension on it, the name, and
    /// under it what the browser knows - "8 pages · 134 KB · pdf" once it is here, its size while
    /// it is still to be fetched, and how far along a download is while one runs.
    ///
    /// Fix: the page was a grey square with the extension in it, and the line under the name was
    /// the caption followed by the extension - the size was never there, because a file message
    /// does not carry it, so most rows read "• pdf".
    func showDoc(_ item: MediaBrowserViewController.DocItem, line: String, downloadFraction: Double?, isHere: Bool,
                 selecting: Bool, picked: Bool) {
        thumb.isHidden = true
        badge.isHidden = true
        page.isHidden = false
        page.kind = item.kind
        title.text = item.fileName
        setLine(line, downloadFraction: downloadFraction, isHere: isHere)
        applyTick(selecting: selecting, picked: picked)
    }

    /// Only the line and the bar - what a download changes many times a second.
    func setLine(_ line: String, downloadFraction: Double?, isHere: Bool) {
        if !isHere, downloadFraction == nil, !line.isEmpty {
            // Still to be fetched: a down arrow says so, as the reference's size line does.
            let text = NSMutableAttributedString()
            let arrow = NSTextAttachment()
            arrow.image = UIImage(systemName: "arrow.down.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .medium))?
                .withTintColor(.secondaryLabel, renderingMode: .alwaysOriginal)
            text.append(NSAttributedString(attachment: arrow))
            text.append(NSAttributedString(string: " " + line, attributes: [.font: detail.font as Any, .foregroundColor: UIColor.secondaryLabel]))
            detail.attributedText = text
        } else {
            detail.attributedText = nil
            detail.text = line
        }
        if let fraction = downloadFraction {
            progress.isHidden = false
            progress.setProgress(Float(fraction), animated: true)
        } else {
            progress.isHidden = true
            progress.setProgress(0, animated: false)
        }
    }

    func showLink(_ item: MediaBrowserViewController.LinkItem, selecting: Bool, picked: Bool) {
        page.isHidden = true
        progress.isHidden = true
        detail.attributedText = nil
        badge.isHidden = false
        badgeLabel.text = "LINK"
        badgeLabel.textColor = .secondaryLabel
        thumb.isHidden = item.thumbFileName.isEmpty
        thumb.image = item.thumbFileName.isEmpty ? nil : Nexilis.imageCache.object(forKey: item.thumbFileName as NSString)
        title.text = URL(string: item.url)?.host ?? item.url
        detail.text = item.url
        applyTick(selecting: selecting, picked: picked)
    }

    /// Choosing turned on or off for a row already on screen.
    func setSelecting(_ selecting: Bool, picked: Bool, animated: Bool) {
        applyTick(selecting: selecting, picked: picked, animated: animated)
    }

    private func applyTick(selecting: Bool, picked: Bool, animated: Bool = false) {
        tick.isHidden = false
        tick.image = UIImage(systemName: picked ? "checkmark.circle.fill" : "circle")
        tick.tintColor = picked ? .systemBlue : .tertiaryLabel
        badgeLeading.constant = selecting ? 50 : 16
        let changes = {
            self.tick.alpha = selecting ? 1 : 0
            self.tick.transform = selecting ? .identity : CGAffineTransform(translationX: -24, y: 0)
            self.contentView.layoutIfNeeded()
        }
        if animated {
            MediaBrowserViewController.selectionMotion(changes)
        } else {
            UIView.performWithoutAnimation(changes)
        }
    }
}

/// A document's page as WhatsApp's Docs list draws it: a grey sheet with its top-right corner
/// turned down, and the extension on a small tag across the foot - the tag in the kind's own
/// colour (the red of a PDF, the blue of a Word file, ...) where it has one, grey otherwise.
final class DocPageIcon: UIView {

    var kind = "" {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        let size = bounds.size
        let fold = size.width * 0.30
        let radius: CGFloat = 4
        let sheet = UIBezierPath()
        sheet.move(to: CGPoint(x: radius, y: 0))
        sheet.addLine(to: CGPoint(x: size.width - fold, y: 0))
        sheet.addLine(to: CGPoint(x: size.width, y: fold))
        sheet.addLine(to: CGPoint(x: size.width, y: size.height - radius))
        sheet.addQuadCurve(to: CGPoint(x: size.width - radius, y: size.height), controlPoint: CGPoint(x: size.width, y: size.height))
        sheet.addLine(to: CGPoint(x: radius, y: size.height))
        sheet.addQuadCurve(to: CGPoint(x: 0, y: size.height - radius), controlPoint: CGPoint(x: 0, y: size.height))
        sheet.addLine(to: CGPoint(x: 0, y: radius))
        sheet.addQuadCurve(to: CGPoint(x: radius, y: 0), controlPoint: .zero)
        sheet.close()
        BrowserPalette.pageSheet.resolvedColor(with: traitCollection).setFill()
        sheet.fill()
        BrowserPalette.pageEdge.resolvedColor(with: traitCollection).setStroke()
        sheet.lineWidth = 1
        sheet.stroke()

        let corner = UIBezierPath()
        corner.move(to: CGPoint(x: size.width - fold, y: 0))
        corner.addLine(to: CGPoint(x: size.width - fold, y: fold - 2))
        corner.addQuadCurve(to: CGPoint(x: size.width - fold + 2, y: fold), controlPoint: CGPoint(x: size.width - fold, y: fold))
        corner.addLine(to: CGPoint(x: size.width, y: fold))
        corner.close()
        BrowserPalette.pageFold.resolvedColor(with: traitCollection).setFill()
        corner.fill()

        let label = DocumentBadge.label(of: kind)
        let coloured = DocPageIcon.colouredKinds.contains(kind)
        let font = UIFont.systemFont(ofSize: 9, weight: .bold)
        var text = NSAttributedString(string: label, attributes: [.font: font])
        var textSize = text.size()
        let maxTagWidth = size.width - 6
        var drawFont = font
        if textSize.width + 8 > maxTagWidth {
            drawFont = .systemFont(ofSize: 9 * (maxTagWidth - 8) / textSize.width, weight: .bold)
            text = NSAttributedString(string: label, attributes: [.font: drawFont])
            textSize = text.size()
        }
        let tagWidth = min(maxTagWidth, textSize.width + 8)
        let tagHeight = textSize.height + 3
        let tag = CGRect(x: (size.width - tagWidth) / 2, y: size.height - tagHeight - size.height * 0.16,
                         width: tagWidth, height: tagHeight)
        (coloured ? DocumentBadge.colour(of: kind) : BrowserPalette.plainTag.resolvedColor(with: traitCollection)).setFill()
        UIBezierPath(roundedRect: tag, cornerRadius: 3).fill()
        NSAttributedString(string: label, attributes: [
            .font: drawFont,
            .foregroundColor: coloured ? UIColor.white : BrowserPalette.plainTagText.resolvedColor(with: traitCollection)
        ]).draw(at: CGPoint(x: tag.midX - textSize.width / 2, y: tag.midY - textSize.height / 2))
    }

    /// The kinds that get their own colour on the tag, as in the reference; everything else
    /// (text, archives, apps) keeps a grey one.
    private static let colouredKinds: Set<String> = [
        "pdf", "doc", "docx", "rtf", "odt", "pages",
        "xls", "xlsx", "xlsm", "csv", "ods", "numbers",
        "ppt", "pptx", "odp", "key"
    ]
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

/// Raises a screen up from the bottom edge.
///
/// A push normally comes in from the side, which reads as one more step along the same thread.
/// Arriving at a collage from a quote is not that: the reader asked to be shown one picture, and
/// the reference answers by lifting the page that picture is on over the conversation. The
/// navigation stack is kept - back still works, the bar is still the bar - so only the way in
/// changes.
///
/// Only the way in. Leaving is UIKit's own pop, and deliberately so: see RisingPushTransition.
final class RisingPushAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.35
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to),
              let fromVC = transitionContext.viewController(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }
        let container = transitionContext.containerView
        let full = container.bounds
        container.addSubview(toVC.view)
        toVC.view.frame = full.offsetBy(dx: 0, dy: full.height)
        // Only the arriving screen moves. Shifting the one underneath would leave it displaced if
        // the transition were cancelled part way, and it has nothing to say here anyway - it is
        // simply what the page is being raised over.
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0, options: [.curveEaseOut], animations: {
            toVC.view.frame = full
            fromVC.view.alpha = 0.4
        }, completion: { _ in
            fromVC.view.alpha = 1
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

/// Lends the rising animation to one push, and hands the stack straight back.
///
/// Fix: this used to keep the stack and animate the pop as well, lowering the page the way it rose.
/// That took the edge swipe away. A navigation controller only offers its own interactive pop while
/// nobody has claimed the pop animation, and a custom animator with no interaction controller to
/// drive it turns the swipe into an animation and a gesture running at once: two copies of the
/// screen lying over each other, going nowhere, leaving a stray picture and a stray back button
/// behind in the stack. Driving it properly means a gesture and a percent-driven transition of our
/// own, to reproduce a reveal UIKit already does better. So the stack is handed back the moment the
/// page is up, and from then on the screen behaves like any other pushed screen: swipe from the
/// edge to go back.
///
/// A navigation controller holds its delegate weakly and only has room for one, so whoever had it
/// is kept and put back.
final class RisingPushTransition: NSObject, UINavigationControllerDelegate {

    private weak var rising: UIViewController?
    private weak var previous: UINavigationControllerDelegate?
    /// Told when the stack has been handed back, so whoever is holding this can let it go.
    var onFinished: (() -> Void)?

    init(rising: UIViewController, previous: UINavigationControllerDelegate?) {
        self.rising = rising
        self.previous = previous
    }

    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push, toVC === rising {
            return RisingPushAnimator()
        }
        return previous?.navigationController?(navigationController,
                                               animationControllerFor: operation,
                                               from: fromVC,
                                               to: toVC)
    }

    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController,
                              animated: Bool) {
        previous?.navigationController?(navigationController, didShow: viewController, animated: animated)
        navigationController.delegate = previous
        onFinished?()
        onFinished = nil
    }
}

extension MediaBrowserViewController: ZoomTransitionChromeProviding {

    /// This screen has no bar above it - the back button, the title and the strip along the bottom
    /// are floated over the pictures themselves. A picture closing out of the viewer is added over
    /// the whole screen, so without this they would be hidden for the length of the move and
    /// reappear in one frame at the end. Back to front, the way they are stacked.
    public var zoomTransitionChrome: [UIView] {
        return [headerScrim, header, footer, actionBar]
    }
}
