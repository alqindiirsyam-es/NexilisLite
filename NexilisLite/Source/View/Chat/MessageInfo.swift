//
//  MessageInfo.swift
//  NexilisLite
//
//  Created by Qindi on 11/08/22.
//

import UIKit
import CoreLocation

class MessageInfo: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    var data: [String: Any?] = [:]
    var dataStatus: [[String: Any?]] = []
    var dataLocation: [String] = []
    private var tableStatus: UITableView!
    var dateMessage = ""
    var dataPerson: [String: String?] = [:]
    var dataGroup: [String: Any?] = [:]
    var isPersonal = true
    let geocoder = CLGeocoder()
    
    // MARK: - Long messages

    /// Puts a long message in the bubble folded, with "Read more" after it. The rule is in
    /// LongMessage, shared with the conversations and starred messages.
    ///
    /// This screen shows one message and nothing else, so opening it is the only interaction it
    /// has - and the fold is what stops a pasted document from burying the delivery details
    /// underneath it.
    private func applyReadMore(to label: UILabel, text: String) {
        let messageId = (data["message_id"] as? String) ?? ""
        label.numberOfLines = 0
        defer {
            // Whether the message was folded or not, a mention in it leads to the person it
            // names - the same as in the conversation this message was opened from.
            label.isUserInteractionEnabled = true
            label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(messageTextTapped(_:))))
        }
        guard LongMessage.isFolded(messageId, text: text) else {
            label.attributedText = text.richText(group_id: mentionGroupId)
            return
        }
        let body = NSMutableAttributedString(attributedString: LongMessage.folded(text).richText(group_id: mentionGroupId))
        body.append(LongMessage.suffix(fontSize: 12 + offset()))
        label.attributedText = body
        let readMore = ReadMoreTap(messageId: messageId, target: self, action: #selector(readMoreTapped(_:)))
        // A tap on a mention belongs to the mention: without this the same touch would open the
        // profile and unfold the message at once, since both recognizers are on this label.
        readMore.delegate = self
        label.addGestureRecognizer(readMore)
    }

    /// The group this message was sent in, or nothing at all for a one-to-one chat.
    ///
    /// A mention is only drawn as one - and only leads anywhere - when the person it names is a
    /// member of the group the message was sent in, so this is what the text has to be built
    /// with for mentions to show up here the way they do in the conversation.
    private var mentionGroupId: String {
        return isPersonal ? "" : (dataGroup["group_id"] as? String ?? "")
    }

    /// A tap on a coloured @mention in the message opens that person's profile.
    ///
    /// Only mentions carry the pin (see `NSAttributedString.Key.mentionPin`), so a tap anywhere
    /// else on the message does nothing, as it did before.
    @objc private func messageTextTapped(_ sender: UITapGestureRecognizer) {
        guard let label = sender.view as? UILabel else { return }
        guard let pin = LinkHighlighting.mentionPin(at: sender.location(in: label), in: label) else { return }
        showProfile(pin: pin)
    }

    /// Opens the profile of the person a pin belongs to. "-999" and "-997" are nobody in
    /// particular (a system message, and @All), and stay where they are.
    private func showProfile(pin: String) {
        let idMe = User.getMyPin() as String?
        if pin == idMe {
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
            controller.data = pin
            controller.flag = .me
            navigationController?.show(controller, sender: nil)
        } else if pin != "-999" && pin != "-997" {
            guard let data = User.getDataCanNil(pin: pin) else {
                return
            }
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
            controller.flag = .friend
            controller.user = data
            controller.name = data.fullName
            controller.data = pin
            controller.picture = data.thumb
            navigationController?.show(controller, sender: nil)
        }
    }

    @objc private func readMoreTapped(_ sender: UITapGestureRecognizer) {
        guard let tap = sender as? ReadMoreTap else {
            return
        }
        LongMessage.expand(tap.messageId)
        tableStatus.reloadData()
    }


    func offset() -> CGFloat{
        guard let fontSize = Int(SecureUserDefaults.shared.value(forKey: "font_size") ?? "0") else { return 0 }
        return CGFloat(fontSize)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Message Info".localized()
        // The screen sits below the navigation bar rather than under it, so where its content
        // begins is settled by its own frame and does not have to wait for a safe-area inset to be
        // worked out - which, during an interactive push, does not happen until the very end.
        edgesForExtendedLayout = []
        extendedLayoutIncludesOpaqueBars = false
        view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.topItem?.backButtonTitle = ""
        
        tableStatus = UITableView(frame: .zero, style: .grouped)
        tableStatus.register(UITableViewCell.self, forCellReuseIdentifier: "cellStatus")
        tableStatus.dataSource = self
        tableStatus.delegate = self
        tableStatus.separatorStyle = .none
        tableStatus.bounces = false
        // Fix: the bubble row is laid out entirely with constraints and nothing ever told the
        // table how tall it comes out, so it was drawn at whatever height the table assumed -
        // which is where the squashed and overlapping bubbles came from.
        tableStatus.rowHeight = UITableView.automaticDimension
        tableStatus.estimatedRowHeight = 80
        // Fix: with an estimate in play, a grouped table lays its headers out at the estimate first
        // and corrects them on a later pass - which is the date arriving a beat after the bubble
        // and everything shifting down. There is nothing to estimate: heightForHeaderInSection
        // knows both heights outright, so it is asked directly.
        tableStatus.estimatedSectionHeaderHeight = 0
        tableStatus.estimatedSectionFooterHeight = 0
        
        getData()
        dateMessage = chatDate(stringDate: data["server_date"] as? String ?? "")

        // Fix: the table was filled while it still had no frame at all, and only put on screen
        // afterwards. It goes up first, and is filled once it has somewhere to draw.
        view.addSubview(tableStatus)
        // Fix: the table ran the full height of the screen and relied on the system inseting its
        // content under the navigation bar. That inset is settled as a transition progresses, so on
        // an interactive push - dragging the screen in from the edge - the first passes had no
        // inset at all: the content sat under the bar with the date hidden behind it, and when the
        // inset finally landed everything shifted down and the date appeared to arrive late. A push
        // from the Info menu settles before anything is drawn, which is why it only showed up one
        // way round. The table is placed below the bar to begin with, so there is nothing to wait
        // for and nothing to shift.
        tableStatus.contentInsetAdjustmentBehavior = .never
        tableStatus.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor)
        tableStatus.tableHeaderView = buildDateHeader()
        tableStatus.reloadData()
        DispatchQueue.global().async{
            self.getAllLocationDesc()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(onStatusChat(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerStatusChat), object: nil)
    }
    
    @objc func onStatusChat(notification: NSNotification) {
        DispatchQueue.main.async{
            self.dataStatus.removeAll()
            self.getData()
            self.tableStatus.reloadData()
        }
    }
    
    private func getData() {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_pin, status, time_delivered, time_read, time_ack, longitude, latitude, message_id FROM MESSAGE_STATUS where message_id='\(data["message_id"]!!)' ORDER BY time_ack DESC, time_read DESC, time_delivered DESC") {
                    var listStatus: [Int] = []
                    while cursorData.next() {
                        let messageId = cursorData.string(forColumnIndex: 7) ?? ""
                        var row: [String: Any?] = [:]
                        row["f_pin"] = cursorData.string(forColumnIndex: 0) ?? ""
                        if dataStatus.count > 0 && dataStatus.contains(where: { $0["message_id"] as? String == messageId && $0["f_pin"] as? String == row["f_pin"] as? String }) {
                            continue
                        }
                        row["status"] = cursorData.string(forColumnIndex: 1) ?? ""
                        row["time_delivered"] = cursorData.string(forColumnIndex: 2) ?? ""
                        row["time_read"] = cursorData.string(forColumnIndex: 3) ?? ""
                        row["time_ack"] = cursorData.string(forColumnIndex: 4) ?? ""
                        row["longitude"] = cursorData.string(forColumnIndex: 5) ?? ""
                        row["latitude"] = cursorData.string(forColumnIndex: 6) ?? ""
                        row["message_id"] = messageId
                        dataStatus.append(row)
                        listStatus.append(Int(row["status"] as! String)!)
                    }
                    data["status"] = "\(listStatus.min() ?? 2)"
                    cursorData.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    func getAllLocationDesc() {
        for data in dataStatus {
            let latitudeString = data["latitude"] as? String ?? ""
            let longitudeString = data["longitude"] as? String ?? ""
            if latitudeString == "" || longitudeString == "" {
                continue
            }
            let latitude = CLLocationDegrees(latitudeString)!
            let longitude = CLLocationDegrees(longitudeString)!
            guard (-90...90).contains(latitude), (-180...180).contains(longitude) else {
                print("Invalid coordinates!")
                continue
            }
            let location = CLLocation(latitude: latitude, longitude: longitude)
            if geocoder.isGeocoding {
                geocoder.cancelGeocode()
            }
            Nexilis.dispatch = DispatchGroup()
            Nexilis.dispatch?.enter()
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                var result = ""
                if let error = error {
                    if let clError = error as? CLError {
                        switch clError.code {
                        case .network:
                            print("Network error: Check your internet connection.")
                        case .geocodeFoundNoResult:
                            print("No results found for the given coordinates.")
                        case .geocodeCanceled:
                            print("Geocoding request was canceled.")
                        case .geocodeFoundPartialResult:
                            print("Partial result found.")
                        default:
                            print("Error: \(clError.localizedDescription)")
                        }
                    } else {
                        print("Unknown error: \(error.localizedDescription)")
                    }
                } else if let placemark = placemarks?.first {
                    if let locality = placemark.locality {
                        result += locality + ", "
                    }
                    if let administrativeArea = placemark.administrativeArea {
                        result += administrativeArea + ", "
                    }
                    if let country = placemark.country {
                        result += country
                    }
                }
                self.dataLocation.append(result)
                if let dispatch = Nexilis.dispatch {
                    dispatch.leave()
                }
            }
            Nexilis.dispatch?.wait()
            Nexilis.dispatch = nil
        }
        DispatchQueue.main.async {
            self.tableStatus.reloadData()
        }
    }
    
    /// Fix: with no height given, a grouped table has to measure each header by laying it out -
    /// which does not happen until the table itself has been laid out, so the date only turned up
    /// after everything else had settled while the bubble was there from the first pass. Both
    /// heights are known: 30 for the date, and 50, which is what the status header builds itself at.
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 50
    }

    /// The date, as the table's own header rather than section zero's.
    ///
    /// Fix: a section header is built when the table lays out its sections, and opening this screen
    /// by dragging it in from the edge is an interactive push - the view controller is created and
    /// loaded at the start of the gesture, long before it has the size it will end up with. The
    /// rows were drawn at the first pass and the header only at the pass after, which is the date
    /// turning up a beat late and the bubble jumping down to make room for it. Opening it from the
    /// Info menu is a plain push, where the size is settled before anything is drawn, so the same
    /// screen behaved differently depending on how it was opened. A table header is part of the
    /// table's own content and goes up with it, whichever way the screen arrives.
    private func buildDateHeader() -> UIView {
        // 46 tall with the pill inset 26 from the top, which leaves the pill at 20 - the height it
        // is in the conversation, and the same 26pt of air above it. Measured off the two screens
        // side by side rather than guessed: the conversation's first row sits under a grouped
        // table's own top padding as well as the header's 10, which is where the extra comes from.
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 46))
        containerView.backgroundColor = .clear

        let dateView = UIView()
        containerView.addSubview(dateView)
        dateView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dateView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 26),
            dateView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            dateView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            dateView.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        dateView.backgroundColor = .orangeColor
        dateView.layer.cornerRadius = 8.0
        dateView.clipsToBounds = true

        let labelDate = UILabel()
        dateView.addSubview(labelDate)
        labelDate.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelDate.centerYAnchor.constraint(equalTo: dateView.centerYAnchor),
            labelDate.centerXAnchor.constraint(equalTo: dateView.centerXAnchor),
            labelDate.leadingAnchor.constraint(equalTo: dateView.leadingAnchor, constant: 10),
            labelDate.trailingAnchor.constraint(equalTo: dateView.trailingAnchor, constant: -10)
        ])
        labelDate.textAlignment = .center
        labelDate.textColor = .secondaryColor
        labelDate.font = UIFont.systemFont(ofSize: 12 + offset(), weight: .medium)
        labelDate.text = dateMessage
        return containerView
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let containerViewStatus = UIView()
        containerViewStatus.backgroundColor = .darkGray
        
        let viewStatus = UIView()
        containerViewStatus.addSubview(viewStatus)
        viewStatus.anchor(top: containerViewStatus.topAnchor, left: containerViewStatus.leftAnchor, bottom: containerViewStatus.bottomAnchor, right: containerViewStatus.rightAnchor, height: 50)
        
        let imageStatus = UIImageView()
        viewStatus.addSubview(imageStatus)
        imageStatus.anchor(left: viewStatus.leftAnchor, bottom: viewStatus.bottomAnchor, paddingLeft: 15, paddingBottom: 5, width: 15, height: 15)
        
        let textStatus = UILabel()
        textStatus.font = .systemFont(ofSize: 12 + offset())
        textStatus.textColor = .white
        viewStatus.addSubview(textStatus)
        textStatus.anchor(left: imageStatus.rightAnchor, bottom: viewStatus.bottomAnchor, paddingLeft: 5.0, paddingBottom: 5.0)
        
        if section == 0 {
            // The date lives in the table's own header now - see buildDateHeader.
            return nil
        } else if section == 1 {
            if !data.isEmpty && data["read_receipts"] as? String == "8" {
                imageStatus.image = UIImage(named: "message_status_ack", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
                textStatus.text = ("Confirmed".localized() + " " + "by".localized()).uppercased()
            } else {
                imageStatus.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
                textStatus.text = ("Read".localized() + " " + "by".localized()).uppercased()
            }
        } else if section == 2 && !data.isEmpty && data["read_receipts"] as? String == "8" {
            imageStatus.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
            textStatus.text = ("Read".localized() + " " + "by".localized()).uppercased()
        } else {
            imageStatus.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
            textStatus.text = ("Delivered".localized() + " " + "to".localized()).uppercased()
        }
        return containerViewStatus
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if !isPersonal {
            var numberSection = 4
            if !data.isEmpty && data["read_receipts"] as? String != "8" {
                numberSection -= 1
            }
            if dataStatus.count == dataStatus.filter({ !($0["time_delivered"] as! String).isEmpty && !($0["time_read"] as! String).isEmpty }).count {
                numberSection -= 1
            }
            if !data.isEmpty && data["read_receipts"] as? String == "8" {
                if dataStatus.count == dataStatus.filter({ !($0["time_read"] as! String).isEmpty && !($0["time_ack"] as! String).isEmpty }).count{
                    numberSection -= 1
                }
            }
            return numberSection
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isPersonal {
            if !data.isEmpty && data["read_receipts"] as? String == "8" {
                return 4
            }
            return 3
        }
        if section == 0 {
            return 1
        } else if section == 1 {
            if !data.isEmpty && data["read_receipts"] as? String == "8" {
                return dataStatus.filter({ ($0["status"] as! String) == "8" }).count + 1
            } else {
                return dataStatus.filter({ ($0["status"] as! String) == "4" }).count + 1
            }
        } else if section == 2 && !data.isEmpty && data["read_receipts"] as? String == "8" {
            return dataStatus.filter({ ($0["status"] as! String) == "4" }).count + 1
        }
        return dataStatus.filter({ ($0["status"] as! String) == "3" }).count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let idMe = User.getMyPin() as String?
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellStatus", for: indexPath as IndexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.accessoryView = nil
        cell.contentConfiguration = nil
        cell.contentView.subviews.forEach({ $0.removeFromSuperview() })
        
        if !isPersonal {
            if indexPath.section != 0 {
                let imageNil = UIImageView()
                imageNil.image = UIImage(systemName: "ellipsis")
                imageNil.contentMode = .center
                imageNil.tintColor = .black
                
                let dataStatusAck = dataStatus.filter({ ($0["status"] as! String) == "8" })
                let dataStatusRead = dataStatus.filter({ ($0["status"] as! String) == "4" })
                let dataStatusDelivered = dataStatus.filter({ ($0["status"] as! String) == "3" })
                
                cell.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
                
                var content = cell.defaultContentConfiguration()
                content.textProperties.font = UIFont.systemFont(ofSize: 14)
                content.imageProperties.maximumSize = CGSize(width: 24, height: 24)
                
                if indexPath.section == 1 {
                    if !data.isEmpty && data["read_receipts"] as? String == "8" {
                        if dataStatusAck.count == 0 || indexPath.row == dataStatusAck.count {
                            cell.contentView.addSubview(imageNil)
                            imageNil.anchor(centerX: cell.centerXAnchor, centerY: cell.centerYAnchor, width: 50, height: 20)
                        } else {
                            let dataProfile = getDataProfile(f_pin: dataStatusAck[indexPath.row]["f_pin"] as! String, message_id: data["message_id"] as! String)
                            content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
                            getImage(name: dataProfile["image_id"]!, placeholderImage: UIImage(named: "Profile---Black", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                                content.image = image
                            })
                            
                            content.text = dataProfile["name"]!
                            if dataLocation.count > 0 && indexPath.row <= dataLocation.count - 1 {
                                content.text = dataProfile["name"]! + " at (\(dataLocation[indexPath.row]))"
                            }
                            
                            let date = Date(milliseconds: Int64(dataStatusAck[indexPath.row]["time_ack"] as! String) ?? 100)
                            let time = DateFormatterPool.shared.string(from: date as Date, format: "HH:mm", localeIdentifier: "id")
                            
                            let viewTimeStatus = UIView()
                            viewTimeStatus.frame = CGRect(x: 0, y: 0, width: 80, height: cell.frame.height)
                            
                            let titleTime = UILabel()
                            viewTimeStatus.addSubview(titleTime)
                            titleTime.anchor(centerX: viewTimeStatus.centerXAnchor, centerY: viewTimeStatus.centerYAnchor)
                            titleTime.font = .systemFont(ofSize: 12 + offset())
                            titleTime.text = "\(chatDate(stringDate: dataStatusAck[indexPath.row]["time_ack"] as! String)) \(time)"
                            
                            cell.accessoryView = viewTimeStatus
                            cell.contentConfiguration = content
                        }
                    } else {
                        if dataStatusRead.count == 0 ||  indexPath.row == dataStatusRead.count {
                            cell.contentView.addSubview(imageNil)
                            imageNil.anchor(centerX: cell.centerXAnchor, centerY: cell.centerYAnchor, width: 50, height: 20)
                        } else {
                            let dataProfile = getDataProfile(f_pin: dataStatusRead[indexPath.row]["f_pin"] as! String, message_id: data["message_id"] as! String)
                            content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
                            getImage(name: dataProfile["image_id"]!, placeholderImage: UIImage(named: "Profile---Black", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                                content.image = image
                            })
                            
                            content.text = dataProfile["name"]!
                            
                            let date = Date(milliseconds: Int64(dataStatusRead[indexPath.row]["time_read"] as! String) ?? 100)
                            let time = DateFormatterPool.shared.string(from: date as Date, format: "HH:mm", localeIdentifier: "id")
                            
                            let viewTimeStatus = UIView()
                            viewTimeStatus.frame = CGRect(x: 0, y: 0, width: 80, height: cell.frame.height)
                            
                            let titleTime = UILabel()
                            viewTimeStatus.addSubview(titleTime)
                            titleTime.anchor(centerX: viewTimeStatus.centerXAnchor, centerY: viewTimeStatus.centerYAnchor)
                            titleTime.font = .systemFont(ofSize: 12 + offset())
                            titleTime.text = "\(chatDate(stringDate: dataStatusRead[indexPath.row]["time_read"] as! String)) \(time)"
                            
                            cell.accessoryView = viewTimeStatus
                            cell.contentConfiguration = content
                        }
                    }
                } else if indexPath.section == 2 && !data.isEmpty && data["read_receipts"] as? String == "8" {
                    if dataStatusRead.count == 0 || indexPath.row == dataStatusRead.count {
                        cell.contentView.addSubview(imageNil)
                        imageNil.anchor(centerX: cell.centerXAnchor, centerY: cell.centerYAnchor, width: 50, height: 20)
                    } else {
                        let dataProfile = getDataProfile(f_pin: dataStatusRead[indexPath.row]["f_pin"] as! String, message_id: data["message_id"] as! String)
                        content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
                        getImage(name: dataProfile["image_id"]!, placeholderImage: UIImage(named: "Profile---Black", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                            content.image = image
                        })
                        
                        content.text = dataProfile["name"]!
                        
                        let date = Date(milliseconds: Int64(dataStatusRead[indexPath.row]["time_read"] as! String) ?? 100)
                        let time = DateFormatterPool.shared.string(from: date as Date, format: "HH:mm", localeIdentifier: "id")
                        
                        let viewTimeStatus = UIView()
                        viewTimeStatus.frame = CGRect(x: 0, y: 0, width: 80, height: cell.frame.height)
                        
                        let titleTime = UILabel()
                        viewTimeStatus.addSubview(titleTime)
                        titleTime.anchor(centerX: viewTimeStatus.centerXAnchor, centerY: viewTimeStatus.centerYAnchor)
                        titleTime.font = .systemFont(ofSize: 12 + offset())
                        titleTime.text = "\(chatDate(stringDate: dataStatusRead[indexPath.row]["time_read"] as! String)) \(time)"
                        
                        cell.accessoryView = viewTimeStatus
                        cell.contentConfiguration = content
                    }
                } else {
                    if dataStatusDelivered.count == 0 || indexPath.row == dataStatusDelivered.count {
                        cell.contentView.addSubview(imageNil)
                        imageNil.anchor(centerX: cell.centerXAnchor, centerY: cell.centerYAnchor, width: 50, height: 20)
                    } else {
                        let dataProfile = getDataProfile(f_pin: dataStatusDelivered[indexPath.row]["f_pin"] as! String, message_id: data["message_id"] as! String)
                        content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
                        getImage(name: dataProfile["image_id"]!, placeholderImage: UIImage(named: "Profile---Black", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                            content.image = image
                        })
                        
                        content.text = dataProfile["name"]!
                        
                        let date = Date(milliseconds: Int64(dataStatusDelivered[indexPath.row]["time_delivered"] as! String) ?? 100)
                        let time = DateFormatterPool.shared.string(from: date as Date, format: "HH:mm", localeIdentifier: "id")
                        
                        let viewTimeStatus = UIView()
                        viewTimeStatus.frame = CGRect(x: 0, y: 0, width: 80, height: cell.frame.height)
                        
                        let titleTime = UILabel()
                        viewTimeStatus.addSubview(titleTime)
                        titleTime.anchor(centerX: viewTimeStatus.centerXAnchor, centerY: viewTimeStatus.centerYAnchor)
                        titleTime.font = .systemFont(ofSize: 12 + offset())
                        titleTime.text = "\(chatDate(stringDate: dataStatusDelivered[indexPath.row]["time_delivered"] as! String)) \(time)"
                        
                        cell.accessoryView = viewTimeStatus
                        cell.contentConfiguration = content
                    }
                }
                return cell
            }
        }
        
        if indexPath.row != 0 {
            cell.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
            var content = cell.defaultContentConfiguration()
            content.textProperties.font = UIFont.systemFont(ofSize: 14 + offset())
            content.imageProperties.maximumSize = CGSize(width: 24, height: 24)
            
            let noStatus = UIImageView(frame: CGRect(x: 0, y: cell.frame.height / 2, width: 50, height: 20))
            noStatus.image = UIImage(systemName: "ellipsis")
            noStatus.contentMode = .center
            noStatus.tintColor = .black
            
            if indexPath.row == 1 {
                if !data.isEmpty && data["read_receipts"] as? String == "8"{
                    content.image = UIImage(named: "message_status_ack", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
                    content.text = "Confirmed".localized()
                    if dataLocation.count > 0 {
                        content.text = "Confirmed".localized() + " at (\(dataLocation[0]))"
                    }
                    if dataStatus.count != 0 {
                        if (dataStatus[0]["time_ack"] as? String ?? "").isEmpty {
                            cell.accessoryView = noStatus
                        } else {
                            let date = Date(milliseconds: Int64(dataStatus[0]["time_ack"] as! String) ?? 100)
                            let time = DateFormatterPool.shared.string(from: date as Date, format: "HH:mm", localeIdentifier: "id")
                            
                            let viewTimeStatus = UIView()
                            viewTimeStatus.frame = CGRect(x: 0, y: 0, width: 80, height: cell.frame.height)
                            
                            let titleTime = UILabel()
                            viewTimeStatus.addSubview(titleTime)
                            titleTime.anchor(centerX: viewTimeStatus.centerXAnchor, centerY: viewTimeStatus.centerYAnchor)
                            titleTime.font = .systemFont(ofSize: 12 + offset())
                            titleTime.text = "\(chatDate(stringDate: dataStatus[0]["time_ack"] as! String)) \(time)"
                            
                            cell.accessoryView = viewTimeStatus
                        }
                    } else {
                        cell.accessoryView = noStatus
                    }
                } else {
                    content.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
                    content.text = "Read".localized()
                    if dataStatus.count != 0 {
                        if (dataStatus[0]["time_read"] as? String ?? "").isEmpty {
                            cell.accessoryView = noStatus
                        } else {
                            let date = Date(milliseconds: Int64(dataStatus[0]["time_read"] as! String) ?? 100)
                            let time = DateFormatterPool.shared.string(from: date as Date, format: "HH:mm", localeIdentifier: "id")
                            
                            let viewTimeStatus = UIView()
                            viewTimeStatus.frame = CGRect(x: 0, y: 0, width: 80, height: cell.frame.height)
                            
                            let titleTime = UILabel()
                            viewTimeStatus.addSubview(titleTime)
                            titleTime.anchor(centerX: viewTimeStatus.centerXAnchor, centerY: viewTimeStatus.centerYAnchor)
                            titleTime.font = .systemFont(ofSize: 12 + offset())
                            titleTime.text = "\(chatDate(stringDate: dataStatus[0]["time_read"] as! String)) \(time)"
                            
                            cell.accessoryView = viewTimeStatus
                        }
                    } else {
                        cell.accessoryView = noStatus
                    }
                }
            } else if indexPath.row == 2 && !data.isEmpty && data["read_receipts"] as? String == "8" {
                content.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
                content.text = "Read".localized()
                if dataStatus.count != 0 {
                    if (dataStatus[0]["time_read"] as? String ?? "").isEmpty {
                        cell.accessoryView = noStatus
                    } else {
                        let date = Date(milliseconds: Int64(dataStatus[0]["time_read"] as! String) ?? 100)
                        let time = DateFormatterPool.shared.string(from: date as Date, format: "HH:mm", localeIdentifier: "id")
                        
                        let viewTimeStatus = UIView()
                        viewTimeStatus.frame = CGRect(x: 0, y: 0, width: 80, height: cell.frame.height)
                        
                        let titleTime = UILabel()
                        viewTimeStatus.addSubview(titleTime)
                        titleTime.anchor(centerX: viewTimeStatus.centerXAnchor, centerY: viewTimeStatus.centerYAnchor)
                        titleTime.font = .systemFont(ofSize: 12 + offset())
                        titleTime.text = "\(chatDate(stringDate: dataStatus[0]["time_read"] as! String)) \(time)"
                        
                        cell.accessoryView = viewTimeStatus
                    }
                } else {
                    cell.accessoryView = noStatus
                }
            } else {
                content.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
                content.text = "Delivered".localized()
                if dataStatus.count == 0 || (dataStatus[0]["time_delivered"] as? String ?? "").isEmpty {
                    cell.accessoryView = noStatus
                } else {
                    let date = Date(milliseconds: Int64(dataStatus[0]["time_delivered"] as! String) ?? 100)
                    let time = DateFormatterPool.shared.string(from: date as Date, format: "HH:mm", localeIdentifier: "id")
                    
                    let viewTimeStatus = UIView()
                    viewTimeStatus.frame = CGRect(x: 0, y: 0, width: 80, height: cell.frame.height)
                    
                    let titleTime = UILabel()
                    viewTimeStatus.addSubview(titleTime)
                    titleTime.anchor(centerX: viewTimeStatus.centerXAnchor, centerY: viewTimeStatus.centerYAnchor)
                    titleTime.font = .systemFont(ofSize: 12 + offset())
                    titleTime.text = "\(chatDate(stringDate: dataStatus[0]["time_delivered"] as! String)) \(time)"
                    
                    cell.accessoryView = viewTimeStatus
                }
            }
            cell.contentConfiguration = content
        } else {
            let thumbChat = (data["thumb_id"] as? String) ?? ""
            let imageChat = (data["image_id"] as? String) ?? ""
            let videoChat = (data["video_id"] as? String) ?? ""
            let fileChat = (data["file_id"] as? String) ?? ""
            // Fix: audio was never read here, so a voice note matched no branch at all and the
            // bubble fell through to printing its own raw message text - "Nexilis_1756...m4a|".
            let audioChat = (data["audio_id"] as? String) ?? ""
            let reffChat = (data["reff_id"] as? String) ?? ""
            
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            
            let containerMessage = BubbleView()
            cell.contentView.addSubview(containerMessage)
            containerMessage.translatesAutoresizingMaskIntoConstraints = false
            
            let timeMessage = UILabel()
            cell.contentView.addSubview(timeMessage)
            timeMessage.translatesAutoresizingMaskIntoConstraints = false
            if (data["read_receipts"] as? String) == "8" {
                timeMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -40).isActive = true
            } else {
                timeMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -5).isActive = true
            }
            
            let statusMessage = UIImageView()
            containerMessage.leadingAnchor.constraint(greaterThanOrEqualTo: cell.contentView.leadingAnchor, constant: 60).isActive = true
            if (data["read_receipts"] as? String) == "8" {
                containerMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -40).isActive = true
            } else {
                containerMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -5).isActive = true
            }
            containerMessage.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5).isActive = true
            containerMessage.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -15).isActive = true
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            if (data["attachment_flag"] as? String == "11" && data["reff_id"]as? String == "") {
                containerMessage.backgroundColor = .clear
            } else {
                containerMessage.backgroundColor = .blueBubbleColor
            }
            containerMessage.layer.cornerRadius = 10.0
            containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
            containerMessage.clipsToBounds = true
            (containerMessage as? BubbleView)?.lift()
            
            timeMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            // Fix: the timestamp only had a right edge, tied to the bubble - so a wide one grew
            // leftwards straight off the cell. Giving it a left edge pushes the bubble across
            // instead of letting the text disappear.
            timeMessage.leadingAnchor.constraint(greaterThanOrEqualTo: cell.contentView.leadingAnchor, constant: 8).isActive = true
            
            cell.contentView.addSubview(statusMessage)
            statusMessage.translatesAutoresizingMaskIntoConstraints = false
            statusMessage.bottomAnchor.constraint(equalTo: timeMessage.topAnchor).isActive = true
            // Fix: time, tick and star stack upwards from the bottom edge with nothing holding
            // them inside the cell. On a short message the stack is taller than the bubble, so
            // the top of it was simply cut off. Now the row grows to fit it.
            statusMessage.topAnchor.constraint(greaterThanOrEqualTo: cell.contentView.topAnchor, constant: 5).isActive = true
            statusMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            statusMessage.widthAnchor.constraint(equalToConstant: 15).isActive = true
            statusMessage.heightAnchor.constraint(equalToConstant: 15).isActive = true
            // Fix: force-cast four times over. A message with no status column - or one stored
            // as anything but a string - crashed this screen outright, and a swipe now opens it.
            let messageStatus = data["status"] as? String ?? ""
            if messageStatus == "1" {
                statusMessage.image = UIImage(systemName: "clock.arrow.circlepath")!.withTintColor(UIColor.lightGray, renderingMode: .alwaysOriginal)
            } else if messageStatus == "2" {
                statusMessage.image = UIImage(named: "checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
            } else if messageStatus == "3" {
                statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
            } else if messageStatus == "8" {
                statusMessage.image = UIImage(named: "message_status_ack", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            } else {
                statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
            }
            
            if data["is_stared"] as? String == "1" {
                let imageStared = UIImageView()
                cell.contentView.addSubview(imageStared)
                imageStared.translatesAutoresizingMaskIntoConstraints = false
                imageStared.bottomAnchor.constraint(equalTo: statusMessage.topAnchor).isActive = true
                imageStared.topAnchor.constraint(greaterThanOrEqualTo: cell.contentView.topAnchor, constant: 5).isActive = true
                imageStared.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
                imageStared.widthAnchor.constraint(equalToConstant: 15).isActive = true
                imageStared.heightAnchor.constraint(equalToConstant: 15).isActive = true
                imageStared.image = UIImage(systemName: "star.fill")
                imageStared.backgroundColor = .clear
                imageStared.tintColor = .systemYellow
            }
            
            if data["read_receipts"] as? String == "8" {
                let imageAckView = UIImageView()
                var imageAck = UIImage(named: "ack_icon_gray", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
                if data["status"] as? String == "8" {
                    imageAck = UIImage(named: "ack_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
                }
                imageAckView.image = imageAck
                cell.contentView.addSubview(imageAckView)
                imageAckView.translatesAutoresizingMaskIntoConstraints = false
                imageAckView.widthAnchor.constraint(equalToConstant: 30).isActive = true
                imageAckView.heightAnchor.constraint(equalToConstant: 30).isActive = true
                imageAckView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
                imageAckView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 30).isActive = true
            }
            
            let messageText = UILabel()
            messageText.numberOfLines = 0
            messageText.lineBreakMode = .byWordWrapping
            containerMessage.addSubview(messageText)
            messageText.translatesAutoresizingMaskIntoConstraints = false
            let topMarginText = messageText.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15)
            // The editors hold this at defaultHigh so anything above the text - a quote that runs
            // to three lines, say - can push the text down instead of fighting a required
            // constraint. Same here, so the bubble matches.
            topMarginText.priority = .defaultHigh
            topMarginText.isActive = true
            messageText.textColor = .black
            if data["attachment_flag"] as? String == "27" || data["attachment_flag"] as? String == "26" || data["attachment_flag"] as? String == "25" || data["message_scope_id"] as? String == "18" {
                messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 85).isActive = true
                let imageLS = UIImageView()
                containerMessage.addSubview(imageLS)
                imageLS.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    imageLS.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15.0),
                    imageLS.trailingAnchor.constraint(equalTo: messageText.leadingAnchor, constant: -10.0),
                    imageLS.centerYAnchor.constraint(equalTo: containerMessage.centerYAnchor),
                    imageLS.heightAnchor.constraint(equalToConstant: 60.0)
                ])
                if (data["attachment_flag"] as? String) == "26" {
                    imageLS.image = UIImage(named: "pb_seminar_wpr", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                } else if (data["attachment_flag"] as? String) == "27" {
                    imageLS.image = UIImage(named: "pb_live_tv", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                } else if data["message_scope_id"] as? String == "18" {
                    imageLS.image = UIImage(systemName: "doc.richtext.fill")
                    imageLS.tintColor = .mainColor
                }
            } else {
                messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            }
            if data["f_pin"] as? String == "-999" && (data["blog_id"] as? String) != nil && !(data["blog_id"] as! String).isEmpty && (data["message_text"] as! String).contains("Berikut QR Code dan detil booking Anda") {
                messageText.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: -115).isActive = true
                let imageQR = UIImageView()
                containerMessage.addSubview(imageQR)
                imageQR.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    imageQR.centerXAnchor.constraint(equalTo: containerMessage.centerXAnchor),
                    imageQR.topAnchor.constraint(equalTo: messageText.bottomAnchor),
                    imageQR.widthAnchor.constraint(equalToConstant: 100.0),
                    imageQR.heightAnchor.constraint(equalToConstant: 100.0)
                ])
                imageQR.image = generateQRCode(from: data["blog_id"] as! String)
            } else {
                messageText.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: -15).isActive = true
            }
            messageText.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
            var textChat = (data["message_text"] as? String) ?? ""
            if (data["lock"] != nil && (data["lock"])! as? String == "1") {
                if (data["f_pin"] as? String == idMe) {
                    textChat = "🚫 _"+"You were deleted this message".localized()+"_"
                } else {
                    textChat = "🚫 _"+"This message was deleted".localized()+"_"
                }
            }
            
            if !audioChat.isEmpty {
                // The conversation trims the name off the front of an audio message's text before
                // it goes into the label. The label is hidden either way, but it is what the bubble
                // takes its width from - so leaving the whole string in made the bubble here far
                // wider than the same message in the conversation.
                textChat = textChat.components(separatedBy: "|")[0]
            }

            let imageSticker = UIImageView()
            if let attachmentFlag = data["attachment_flag"], let attachmentFlag = attachmentFlag as? String {
                if attachmentFlag == "27" || attachmentFlag == "26" { // live streaming
                    // Fix: force try and force unwrap. A message of this kind whose text is not
                    // valid JSON - a truncated payload, or one from an older sender - took the
                    // whole screen down rather than simply not drawing its details.
                    let data = textChat
                    if let payload = data.data(using: .utf8),
                       let json = (try? JSONSerialization.jsonObject(with: payload, options: [])) as? [String: Any] {
                        Database.shared.database?.inTransaction({ fmdb, rollback in
                            let title = json["title"] as? String ?? ""
                            let description = json["description"] as? String ?? ""
                            let start = json["time"] as? Int64 ?? 0
                            let by = json["by"] as? String ?? ""
                            var type = "*Live Streaming*"
                            if attachmentFlag == "26" {
                                type = "*Seminar*"
                            }
                            if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || last_name from BUDDY where f_pin = '\(by)'"), c.next() {
                                let name = c.string(forColumnIndex: 0)!
                                messageText.attributedText = "\(type) \nTitle: \(title) \nDescription: \(description) \nStart: \(Date(milliseconds: start).format(dateFormat: "dd/MM/yyyy HH:mm")) \nBroadcaster: \(name)".richText()
                                c.close()
                            } else {
                                messageText.attributedText = ("\(type) \nTitle: \(title) \nDescription: \(description) \nStart: \(Date(milliseconds: start).format(dateFormat: "dd/MM/yyyy HH:mm"))").richText()
                            }
                        })
                    }
                }
                else if attachmentFlag == "25" {
                    // Fix: force try and force unwrap. A message of this kind whose text is not
                    // valid JSON - a truncated payload, or one from an older sender - took the
                    // whole screen down rather than simply not drawing its details.
                    let data = textChat
                    if let payload = data.data(using: .utf8),
                       let json = (try? JSONSerialization.jsonObject(with: payload, options: [])) as? [String: Any] {
                        Database.shared.database?.inTransaction({ fmdb, rollback in
                            var stringLS = ""
                            let title = json["title"] as? String ?? ""
                            let blog = json["blog"] as? String ?? ""
                            let by = json["by"] as? String ?? ""
                            let start = json["time"] as? Int64 ?? 0
                            let textVCR = "Video Conference Room".localized()
                            var type = "*\(textVCR)*"
                            if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || last_name from BUDDY where f_pin = '\(by)'"), c.next() {
                                let name = c.string(forColumnIndex: 0)!
                                stringLS = "\(type) \nTitle: \(title) \nStart: \(Date(milliseconds: start).format(dateFormat: "dd/MM/yyyy HH:mm")) \nInitiator: \(name) \n\n*^Room ID: ^*\n*^\(blog)^*"
                            }
                            messageText.attributedText = stringLS.richText()
                        })
                    }
                }
                else if attachmentFlag == "11" {
                    messageText.text = ""
                    topMarginText.constant = topMarginText.constant + 100
                    containerMessage.addSubview(imageSticker)
                    imageSticker.translatesAutoresizingMaskIntoConstraints = false
                    if (reffChat == "") {
                        imageSticker.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
                        imageSticker.widthAnchor.constraint(equalToConstant: 80).isActive = true
                    } else {
                        imageSticker.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
                    }
                    imageSticker.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                    imageSticker.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                    imageSticker.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                    var imageStickerBundle = UIImage(named: (textChat.component(1, separatedBy: "/")), in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                    if imageStickerBundle == nil {
                        imageStickerBundle = UIImage(named: (textChat.component(1, separatedBy: "/")), in: Bundle.resourcesMediaBundle(for: Nexilis.self), with: nil)
                    }
                    imageSticker.image = imageStickerBundle //resourcesMediaBundle
                    imageSticker.contentMode = .scaleAspectFit
                } else if data["message_scope_id"] as! String == "18" {
                    let data = textChat
                    if let jsonForm = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                        let form_title = jsonForm["form_title"] as! String
                        let club_type = jsonForm["club_type"] as! String
                        let province = jsonForm["province"] as! String
                        let club = jsonForm["club"] as! String
                        messageText.attributedText = "*\(form_title.replacingOccurrences(of: "+", with: " "))* \nClub Type: \(club_type) \nProvince: \(province) \nClub Name: \(club) ".richText()
                    }
                }
                else {
                    applyReadMore(to: messageText, text: textChat)
                }
            } else {
                applyReadMore(to: messageText, text: textChat)
            }
            
            let stringDate = (data["server_date"] as? String) ?? ""
            if !stringDate.isEmpty {
                let date = Date(milliseconds: Int64(stringDate) ?? 100)
                timeMessage.text = DateFormatterPool.shared.string(from: date as Date, format: "HH:mm", localeIdentifier: "id")
                timeMessage.font = UIFont.systemFont(ofSize: 10 + offset(), weight: .medium)
                timeMessage.textColor = .lightGray
            }
            
            let imageThumb = UIImageView()
            let containerViewFile = UIView()

            // Fix: audio was drawn here as a document card of its own making, which is not what a
            // voice note looks like anywhere else in the app. It is the conversation's own row now,
            // built from the same view, so the two cannot say different things about one note.
            if !audioChat.isEmpty {
                messageText.isHidden = true
                // Hidden or not, the label is still laid out, and it must not be what decides how
                // wide the bubble comes out - the audio row is.
                messageText.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                messageText.setContentHuggingPriority(.defaultLow, for: .horizontal)
                let incomingAudio = (data["f_pin"] as? String) != idMe
                let isVoiceNoteAudio = (data["attachment_flag"] as? String) == "60"
                let contAudio = AudioBubbleContent(incoming: incomingAudio,
                                                   isVoiceNote: isVoiceNoteAudio,
                                                   bubbleColour: containerMessage.backgroundColor ?? .white,
                                                   traits: traitCollection,
                                                   fontOffset: offset())
                containerMessage.addSubview(contAudio)
                contAudio.anchor(top: containerMessage.topAnchor, left: containerMessage.leftAnchor, bottom: containerMessage.bottomAnchor, right: containerMessage.rightAnchor, paddingTop: 15, paddingLeft: 10, paddingBottom: 10, paddingRight: 12)
                contAudio.setPicture(named: profileThumb(forPin: data["f_pin"] as? String ?? ""))
                describeAudio(in: contAudio, named: audioChat)
            }

            // A round video note is a circle, not a bubble with a picture in it. Here it is only
            // shown - this screen is a record of a message, not a place to watch one - so it goes
            // in as a preview with no player behind it at all.
            if VideoNote.isNote(videoChat) {
                containerMessage.backgroundColor = .clear
                containerMessage.layer.shadowOpacity = 0
                messageText.isHidden = true

                let note = VideoNoteBubbleView()
                containerMessage.addSubview(note)
                note.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    note.topAnchor.constraint(equalTo: containerMessage.topAnchor),
                    note.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor),
                    note.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor),
                    note.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor)
                ])
                note.configure(videoId: videoChat, thumbId: thumbChat, state: .preview)
                return cell
            }
            if (!thumbChat.isEmpty) {
                // One measurement, not two: the width and the height come from the same look
                // at the file.
                let thumbSize = ListGroupImages.getImageSize(image: thumbChat, screenWidth: self.view.frame.size.width * 0.6, screenHeight: 305)
                let getHeightImage: CGFloat = thumbSize.height
                let getWidthImage: CGFloat = thumbSize.width
                // The one height both the picture and the text margin below it are built from, so
                // the two can never drift apart - which is what a separate `< 40 ? 45 : h + 5`
                // written out by hand invites.
                let imageSlotHeight: CGFloat = getHeightImage < 40 ? 40 : getHeightImage
                // The +5 pays for the 5pt gap the picture leaves above the text below it; without
                // it the bubble is five short and the picture is squeezed by that much.
                topMarginText.constant = topMarginText.constant + imageSlotHeight + 5
                
                containerMessage.addSubview(imageThumb)
                imageThumb.frame = CGRect(x: 0, y: 0, width: getWidthImage, height: getHeightImage)
                imageThumb.translatesAutoresizingMaskIntoConstraints = false
                let dataReply = queryMessageReply(message_id: reffChat)
                if (dataReply.count == 0) {
                    imageThumb.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
                }
                imageThumb.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                imageThumb.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                imageThumb.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                // Fix: the width was required, on a view already pinned to both sides of the
                // bubble - three required constraints for one dimension, so Auto Layout broke one
                // of them at runtime and the picture took whatever geometry that left. A preferred
                // width and a required ceiling say the same thing without the contradiction.
                let imgWidthConstraint = imageThumb.widthAnchor.constraint(equalToConstant: getWidthImage)
                imgWidthConstraint.priority = .defaultHigh
                imgWidthConstraint.isActive = true
                let imgMaxWidthConstraint = imageThumb.widthAnchor.constraint(lessThanOrEqualTo: containerMessage.widthAnchor, constant: -30)
                imgMaxWidthConstraint.priority = .required
                imgMaxWidthConstraint.isActive = true
                // Fix: the real defect. The picture never had a height of its own - it was held
                // between the bubble's top and the text below, and the only thing asking for a
                // particular size was the text margin. So the height the file was measured at was
                // never actually applied to anything: measured 329pt tall on screen against a
                // ceiling of 305 the code had asked for, and starting 29pt above the top of the
                // bubble, because the required top and the required bottom could not both hold and
                // the top is the one that gave. A height, at the same priority as the margin that
                // was bumped to match it, so the two agree instead of one being inferred from the
                // other.
                let imgHeightConstraint = imageThumb.heightAnchor.constraint(equalToConstant: imageSlotHeight)
                imgHeightConstraint.priority = .defaultHigh
                imgHeightConstraint.isActive = true
                imageThumb.layer.cornerRadius = 5.0
                imageThumb.clipsToBounds = true
                imageThumb.contentMode = .scaleAspectFill
                // Fix: an image view carries the size of the picture inside it, and this one has no
                // height of its own - it is held between the top of the bubble and the text below.
                // So the thumbnail's own dimensions pushed against that margin and won, and the
                // picture grew far past its slot. It only became visible when the bubble was given
                // its shadow: a shadow cannot be drawn by a layer that clips, so the clipping that
                // had been quietly hiding this overflow went with it. The same four lines already
                // hold the bubble in the editors; this screen never got them.
                imageThumb.setContentHuggingPriority(.defaultLow, for: .vertical)
                imageThumb.setContentHuggingPriority(.defaultLow, for: .horizontal)
                imageThumb.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
                imageThumb.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                
                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                if let dirPath = paths.first {
                    let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(thumbChat)
                    let image    = UIImage(contentsOfFile: thumbURL.path)
//                    let image = UIGraphicsRenderer.renderImageAt(url: thumbURL as NSURL, size: CGSize(width: 250, height: 250))
                    imageThumb.image = image
                    
                    let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(videoChat)
                    let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(imageChat)
                    if !FileManager.default.fileExists(atPath: imageURL.path) && !FileManager.default.fileExists(atPath: videoURL.path) && !FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) && !FileEncryption.shared.isSecureExists(filename: videoURL.lastPathComponent) {
                        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
                        let blurEffectView = UIVisualEffectView(effect: blurEffect)
                        blurEffectView.frame = CGRect(x: 0, y: 0, width: imageThumb.frame.size.width, height: imageThumb.frame.size.height)
                        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                        imageThumb.addSubview(blurEffectView)
                        if !imageChat.isEmpty {
                            let imageDownload = UIImageView(image: UIImage(systemName: "arrow.down.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .default)))
                            imageThumb.addSubview(imageDownload)
                            imageDownload.tintColor = .black.withAlphaComponent(0.3)
                            imageDownload.translatesAutoresizingMaskIntoConstraints = false
                            imageDownload.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                            imageDownload.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                        }
                    }
                    
                }
                
                if (videoChat != "") {
                    let imagePlay = UIImageView(image: UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .default))?.imageWithInsets(insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))?.withTintColor(.white))
                    imagePlay.circle()
                    imageThumb.addSubview(imagePlay)
                    imagePlay.backgroundColor = .black.withAlphaComponent(0.3)
                    imagePlay.translatesAutoresizingMaskIntoConstraints = false
                    imagePlay.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                    imagePlay.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                }
                
                if (data["progress"] as! Double != 100.0 && data["f_pin"] as? String == idMe) {
                    let container = UIView()
                    imageThumb.addSubview(container)
                    container.translatesAutoresizingMaskIntoConstraints = false
                    container.bottomAnchor.constraint(equalTo: imageThumb.bottomAnchor, constant: -10).isActive = true
                    container.leadingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: 10).isActive = true
                    container.widthAnchor.constraint(equalToConstant: 30).isActive = true
                    container.heightAnchor.constraint(equalToConstant: 30).isActive = true
                    container.backgroundColor = .white.withAlphaComponent(0.1)
                    let circlePath = UIBezierPath(arcCenter: CGPoint(x: 10, y: 20), radius: 15, startAngle: -(.pi / 2), endAngle: .pi * 2, clockwise: true)
                    let trackShape = CAShapeLayer()
                    trackShape.path = circlePath.cgPath
                    trackShape.fillColor = UIColor.black.withAlphaComponent(0.3).cgColor
                    trackShape.lineWidth = 3
                    trackShape.strokeColor = UIColor.blueBubbleColor.withAlphaComponent(0.3).cgColor
                    container.backgroundColor = .clear
                    container.layer.addSublayer(trackShape)
                    let shapeLoading = CAShapeLayer()
                    shapeLoading.path = circlePath.cgPath
                    shapeLoading.fillColor = UIColor.clear.cgColor
                    shapeLoading.lineWidth = 3
                    shapeLoading.strokeEnd = 0
                    shapeLoading.strokeColor = UIColor.blueBubbleColor.cgColor
                    container.layer.addSublayer(shapeLoading)
                    let imageupload = UIImageView(image: UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                    imageupload.tintColor = .white
                    container.addSubview(imageupload)
                    imageupload.translatesAutoresizingMaskIntoConstraints = false
                    imageupload.bottomAnchor.constraint(equalTo: imageThumb.bottomAnchor, constant: -10).isActive = true
                    imageupload.leadingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: 10).isActive = true
                    imageupload.widthAnchor.constraint(equalToConstant: 20).isActive = true
                    imageupload.heightAnchor.constraint(equalToConstant: 20).isActive = true
                }
            }
            
            let attachmentName = fileChat
            if !attachmentName.isEmpty, (data["message_scope_id"] as? String) != "18" {
                topMarginText.constant = topMarginText.constant + 55
                
                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                // Fix: an empty name splits into nothing, and this then read element -1 of it.
                let arrExtFile = (textChat.components(separatedBy: "|").first ?? "").split(separator: ".")
                let finalExtFile = arrExtFile.last ?? Substring(URL(fileURLWithPath: attachmentName).pathExtension)
                if let dirPath = paths.first {
                    let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(attachmentName)
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        if let dataFile = try? Data(contentsOf: fileURL) {
                            var sizeOfFile = Int(dataFile.count / 1000000)
                            if (sizeOfFile < 1) {
                                sizeOfFile = Int(dataFile.count / 1000)
                                if (finalExtFile.count > 4) {
                                    messageText.text = "\(sizeOfFile) kB \u{2022} TXT"
                                }else {
                                    messageText.text = "\(sizeOfFile) kB \u{2022} \(finalExtFile.uppercased())"
                                }
                            } else {
                                if (finalExtFile.count > 4) {
                                    messageText.text = "\(sizeOfFile) MB \u{2022} TXT"
                                }else {
                                    messageText.text = "\(sizeOfFile) MB \u{2022} \(finalExtFile.uppercased())"
                                }
                            }
                        } else {
                            messageText.text = ""
                        }
                    }
                    else if FileEncryption.shared.isSecureExists(filename: attachmentName) {
                        if var dataFile = try? FileEncryption.shared.readSecure(filename: attachmentName) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: dataFile)
                            if dataDecrypt != nil {
                                dataFile = dataDecrypt!
                            }
                            var sizeOfFile = Int(dataFile.count / 1000000)
                            if (sizeOfFile < 1) {
                                sizeOfFile = Int(dataFile.count / 1000)
                                if (finalExtFile.count > 4) {
                                    messageText.text = "\(sizeOfFile) kB \u{2022} TXT"
                                }else {
                                    messageText.text = "\(sizeOfFile) kB \u{2022} \(finalExtFile.uppercased())"
                                }
                            } else {
                                if (finalExtFile.count > 4) {
                                    messageText.text = "\(sizeOfFile) MB \u{2022} TXT"
                                }else {
                                    messageText.text = "\(sizeOfFile) MB \u{2022} \(finalExtFile.uppercased())"
                                }
                            }
                        } else {
                            messageText.text = ""
                        }
                    }
                }
                
                containerMessage.addSubview(containerViewFile)
                containerViewFile.translatesAutoresizingMaskIntoConstraints = false
                let dataReply = queryMessageReply(message_id: reffChat)
                if (dataReply.count == 0) {
                    containerViewFile.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
                }
                containerViewFile.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                containerViewFile.bottomAnchor.constraint(equalTo:messageText.topAnchor, constant: -5).isActive = true
                containerViewFile.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                containerViewFile.heightAnchor.constraint(equalToConstant: 50).isActive = true
                containerViewFile.backgroundColor = .black.withAlphaComponent(0.2)
                containerViewFile.layer.cornerRadius = 5.0
                containerViewFile.clipsToBounds = true
                
                let imageFile = UIImageView(image: UIImage(systemName: "doc.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .bold, scale: .default)))
                containerViewFile.addSubview(imageFile)
                let nameFile = UILabel()
                containerViewFile.addSubview(nameFile)
                
                imageFile.translatesAutoresizingMaskIntoConstraints = false
                imageFile.leadingAnchor.constraint(equalTo: containerViewFile.leadingAnchor, constant: 5).isActive = true
                imageFile.trailingAnchor.constraint(equalTo: nameFile.leadingAnchor, constant: -5).isActive = true
                imageFile.centerYAnchor.constraint(equalTo: containerViewFile.centerYAnchor).isActive = true
                imageFile.widthAnchor.constraint(equalToConstant: 30).isActive = true
                imageFile.heightAnchor.constraint(equalToConstant: 30).isActive = true
                imageFile.tintColor = .docColor
                
                nameFile.translatesAutoresizingMaskIntoConstraints = false
                nameFile.centerYAnchor.constraint(equalTo: containerViewFile.centerYAnchor).isActive = true
                nameFile.widthAnchor.constraint(lessThanOrEqualToConstant: 200).isActive = true
                nameFile.font = UIFont.systemFont(ofSize: 12 + offset(), weight: .medium)
                nameFile.textColor = .white
                nameFile.text = textChat.components(separatedBy: "|").first ?? ""
                
                // Fix: force cast. A row that carries no progress at all - which is any message
                // that did not come from a transfer - brought the screen down.
                if ((data["progress"] as? Double) ?? 100.0) != 100.0 {
                    let containerLoading = UIView()
                    containerViewFile.addSubview(containerLoading)
                    containerLoading.translatesAutoresizingMaskIntoConstraints = false
                    containerLoading.centerYAnchor.constraint(equalTo: containerViewFile.centerYAnchor).isActive = true
                    containerLoading.leadingAnchor.constraint(equalTo: nameFile.trailingAnchor, constant: 5).isActive = true
                    containerLoading.trailingAnchor.constraint(equalTo: containerViewFile.trailingAnchor, constant: -5).isActive = true
                    containerLoading.widthAnchor.constraint(equalToConstant: 30).isActive = true
                    containerLoading.heightAnchor.constraint(equalToConstant: 30).isActive = true
                    let circlePath = UIBezierPath(arcCenter: CGPoint(x: 15, y: 15), radius: 10, startAngle: -(.pi / 2), endAngle: .pi * 2, clockwise: true)
                    let trackShape = CAShapeLayer()
                    trackShape.path = circlePath.cgPath
                    trackShape.fillColor = UIColor.clear.cgColor
                    trackShape.lineWidth = 5
                    trackShape.strokeColor = UIColor.blueBubbleColor.withAlphaComponent(0.3).cgColor
                    containerLoading.layer.addSublayer(trackShape)
                    let shapeLoading = CAShapeLayer()
                    shapeLoading.path = circlePath.cgPath
                    shapeLoading.fillColor = UIColor.clear.cgColor
                    shapeLoading.lineWidth = 3
                    shapeLoading.strokeEnd = 0
                    shapeLoading.strokeColor = UIColor.secondaryColor.cgColor
                    containerLoading.layer.addSublayer(shapeLoading)
                    var imageupload = UIImageView(image: UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                    if data["f_pin"] as? String != idMe {
                        imageupload = UIImageView(image: UIImage(systemName: "arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                        shapeLoading.strokeColor = UIColor.blueBubbleColor.cgColor
                    }
                    imageupload.tintColor = .white
                    containerLoading.addSubview(imageupload)
                    imageupload.translatesAutoresizingMaskIntoConstraints = false
                    imageupload.centerYAnchor.constraint(equalTo: containerLoading.centerYAnchor).isActive = true
                    imageupload.centerXAnchor.constraint(equalTo: containerLoading.centerXAnchor).isActive = true
                } else {
                    nameFile.trailingAnchor.constraint(equalTo: containerViewFile.trailingAnchor, constant: -5).isActive = true
                }
            }
            
            if reffChat != "", (data["message_scope_id"] as? String) != "18" {
                let dataReply = queryMessageReply(message_id: reffChat)
                if dataReply.count != 0 {
                    topMarginText.constant = topMarginText.constant + 55
                    
                    // Measured off a WhatsApp bubble: the bubble is #D6E8FC and the quote inside it is
                    // #D3E1F2 - the bubble lifted toward grey, not darkened with black, which is a
                    // light grey at 22%. Taken as an overlay it holds on any bubble colour, and the
                    // text on it is the foreground held back rather than a colour of its own: that
                    // #303237 quote is black at 77%.
                    //
                    // Dark mode turns the overlay over. WhatsApp's dark bubble is a deep green, so
                    // lifting it still leaves somewhere dark to write on; ours is a bright blue
                    // (#367dd9), and lifting that leaves white text at 2.2:1 - unreadable. Darkening
                    // instead moves the quote away from the bubble the same way, and the text goes to
                    // 87% for the same reason WhatsApp can afford 60% and we cannot.
                    let isDarkQuote = self.traitCollection.userInterfaceStyle == .dark
                    let quoteOverlay: UIColor = isDarkQuote
                        ? .black.withAlphaComponent(0.22)
                        : UIColor(white: 0.784, alpha: 0.22)
                    let quotedTextColour: UIColor = isDarkQuote
                        ? .white.withAlphaComponent(0.87)
                        : .black.withAlphaComponent(0.77)

                    let containerReply = UIView()
                    containerMessage.addSubview(containerReply)
                    containerReply.translatesAutoresizingMaskIntoConstraints = false
                    containerReply.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                    containerReply.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
                    if thumbChat != "" {
                        containerReply.bottomAnchor.constraint(equalTo: imageThumb.topAnchor, constant: -5).isActive = true
                    } else if fileChat != "" {
                        containerReply.bottomAnchor.constraint(equalTo: containerViewFile.topAnchor, constant: -5).isActive = true
                    } else if data["attachment_flag"] as? String == "11" {
                        containerReply.bottomAnchor.constraint(equalTo: imageSticker.topAnchor, constant: -5).isActive = true
                    } else {
                        containerReply.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                    }
                    containerReply.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                    // A fixed 50 pinned the quote to roughly two lines whatever it held. The
                    // editors give it a floor and let it grow, which is what the third line needs.
                    let minHeightConstraint = containerReply.heightAnchor.constraint(greaterThanOrEqualToConstant: 50 + (self.offset()*3))
                    minHeightConstraint.priority = .defaultHigh
                    minHeightConstraint.isActive = true
                    containerReply.backgroundColor = quoteOverlay
                    containerReply.layer.cornerRadius = 5
                    containerReply.clipsToBounds = true
                    
                    let leftReply = UIView()
                    containerReply.addSubview(leftReply)
                    leftReply.translatesAutoresizingMaskIntoConstraints = false
                    leftReply.leadingAnchor.constraint(equalTo: containerReply.leadingAnchor).isActive = true
                    leftReply.topAnchor.constraint(equalTo: containerReply.topAnchor).isActive = true
                    leftReply.bottomAnchor.constraint(equalTo: containerReply.bottomAnchor).isActive = true
                    leftReply.widthAnchor.constraint(equalToConstant: 3).isActive = true
                    leftReply.layer.cornerRadius = 5
                    leftReply.clipsToBounds = true
                    leftReply.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
                    
                    let titleReply = UILabel()
                    containerReply.addSubview(titleReply)
                    titleReply.translatesAutoresizingMaskIntoConstraints = false
                    titleReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
                    titleReply.topAnchor.constraint(equalTo: containerReply.topAnchor, constant: 10).isActive = true
                    titleReply.trailingAnchor.constraint(lessThanOrEqualTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    titleReply.font = UIFont.systemFont(ofSize: 12 + offset()).bold
                    // Fix: every field in this quote was read from `data` - the message being
                    // inspected - and not from dataReply, which is the message it replies to and
                    // the whole reason queryMessageReply was called just above. The quote showed
                    // the message its own text and its own attachment back, never the one quoted.
                    let replyPin = (dataReply["f_pin"] as? String) ?? ""
                    if replyPin == idMe {
                        titleReply.text = "You".localized()
                    } else if isPersonal {
                        // Fix: `dataPerson["name"]!!` - a double force unwrap on a dictionary that
                        // is only filled in for personal chats.
                        titleReply.text = (dataPerson["name"] ?? "") ?? ""
                    } else {
                        titleReply.text = getDataProfile(f_pin: replyPin,
                                                         message_id: (dataReply["message_id"] as? String) ?? "")["name"]
                    }
                    // The accent follows the bubble the quote sits in, not the quoted author -
                    // same rule as the editors.
                    // The name and the bar take the colour of whoever is being quoted, the way
                    // WhatsApp gives everyone in a group one of their own. White only worked here
                    // while the quote sat on a black overlay; on the bubble's own colour it went.
                    let quoteGround = UIColor.composite(quoteOverlay, over: containerMessage.backgroundColor ?? .white)
                    let quoteAccent = UIColor.participant(pin: replyPin, conversation: (isPersonal ? (dataPerson["f_pin"] ?? "") ?? "" : (dataGroup["group_id"] as? String ?? "")),
                                                              members: isPersonal ? [(dataPerson["f_pin"] ?? "") ?? ""] : [],
                                                              on: quoteGround)
                    titleReply.textColor = quoteAccent
                    leftReply.backgroundColor = quoteAccent
                    
                    let contentReply = UILabel()
                    contentReply.numberOfLines = 3
                    // The quote sits between two required pins - the top of the bubble and the top
                    // of the message text - so its height is whatever those leave it, and the 55
                    // points reserved above the text only ever left room for one line. The label
                    // has to outrank the constraint holding the text in place (defaultHigh) for
                    // the box to grow to the second and third line.
                    contentReply.setContentCompressionResistancePriority(.required, for: .vertical)
                    titleReply.setContentCompressionResistancePriority(.required, for: .vertical)
                    containerReply.addSubview(contentReply)
                    contentReply.translatesAutoresizingMaskIntoConstraints = false
                    contentReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
                    contentReply.bottomAnchor.constraint(equalTo: containerReply.bottomAnchor, constant: -10).isActive = true
                    // Required, and a minimum rather than an equality. At defaultHigh this was the
                    // cheapest constraint in the box to break, so a quote too tall for the space left
                    // for it was resolved by dropping the text on top of the name instead of making
                    // the box taller. Required, the box has to grow and the constraint holding the
                    // message text below it - which is the one meant to give way - does.
                    let topConstraintContent = contentReply.topAnchor.constraint(greaterThanOrEqualTo: titleReply.bottomAnchor)
                    topConstraintContent.isActive = true
                    contentReply.font = UIFont.systemFont(ofSize: 11 + offset())
                    // Fix: force casts on values that come straight out of the database, where a
                    // NULL column arrives as nil. Any of the six could bring the screen down.
                    let message_text = (dataReply["message_text"] as? String) ?? ""
                    let attachment_flag = (dataReply["attachment_flag"] as? String) ?? ""
                    let thumb_chat = (dataReply["thumb_id"] as? String) ?? ""
                    let image_chat = (dataReply["image_id"] as? String) ?? ""
                    let video_chat = (dataReply["video_id"] as? String) ?? ""
                    let file_chat = (dataReply["file_id"] as? String) ?? ""
                    let audio_chat = (dataReply["audio_id"] as? String) ?? ""
                    if (attachment_flag == "0" && thumb_chat == "") {
                        contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                        contentReply.attributedText = message_text.richText(fontSize: 11 + offset(), group_id: mentionGroupId)
                    } else if (attachment_flag == "1" || image_chat != "") {
                        if (message_text == "") {
                            contentReply.text = "📷 Photo".localized()
                        } else {
                            contentReply.attributedText = message_text.richText(fontSize: 11 + offset(), group_id: mentionGroupId)
                        }
                    } else if (attachment_flag == "2" || video_chat != "") {
                        if (message_text == "") {
                            // A round video note is quoted as one, with its length; an ordinary video
                            // is quoted the way it always was.
                            if let noteLine = VideoNote.quotedLine(videoId: video_chat,
                                                                   font: contentReply.font,
                                                                   colour: contentReply.textColor ?? .gray) {
                                contentReply.attributedText = noteLine
                            } else {
                                contentReply.text = "📹 Video".localized()
                            }
                        } else {
                            contentReply.attributedText = message_text.richText(fontSize: 11 + offset(), group_id: mentionGroupId)
                        }
                    } else if (attachment_flag == "6" || file_chat != ""){
                        contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                        contentReply.text = "📄 \(message_text.components(separatedBy: "|")[0])"
                    } else if (attachment_flag == "11") {
                        contentReply.text = "❤️ Sticker"
                    } else if !audio_chat.isEmpty {
                        contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                        contentReply.attributedText = Utils.audioPreviewLine(attachmentFlag: attachment_flag,
                                                                            audioName: audio_chat,
                                                                            font: contentReply.font,
                                                                            colour: quotedTextColour)
                    }
// WhatsApp writes the quote in the foreground colour held back a little, not in a
                    // colour of its own: #303237 on that #D3E1F2 quote is black at 77%. Its dark
                    // theme does the same the other way round, white at 60%.
                    contentReply.textColor = quotedTextColour
                    
                    if (attachment_flag == "1" || attachment_flag == "2" || image_chat != "" || video_chat != "") {
                        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                        if let dirPath = paths.first {
                            // Only the plain file was read, which a receiver often does not have -
                            // nobody downloads the thumbnail of a message they have only been shown
                            // a quote of. See VideoNote.quotedStill.
                            let imageThumb = UIImageView()
                            VideoNote.loadQuotedStill(named: thumb_chat, into: imageThumb)
                            containerReply.addSubview(imageThumb)
                            // A video note is round wherever it is shown, a quote included; the square corner
                            // is what every other kind of attachment keeps.
                            imageThumb.layer.cornerRadius = VideoNote.isNote(video_chat) ? 15.0 : 2.0
                            imageThumb.clipsToBounds = true
                            imageThumb.contentMode = .scaleAspectFill
                            imageThumb.translatesAutoresizingMaskIntoConstraints = false
                            imageThumb.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -10).isActive = true
                            imageThumb.centerYAnchor.constraint(equalTo: containerReply.centerYAnchor).isActive = true
                            imageThumb.widthAnchor.constraint(equalToConstant: 30).isActive = true
                            imageThumb.heightAnchor.constraint(equalToConstant: 30).isActive = true
                            
                            if (attachment_flag == "2") {
                                let imagePlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
                                imageThumb.addSubview(imagePlay)
                                imagePlay.clipsToBounds = true
                                imagePlay.translatesAutoresizingMaskIntoConstraints = false
                                imagePlay.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                                imagePlay.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                                imagePlay.widthAnchor.constraint(equalToConstant: 10).isActive = true
                                imagePlay.heightAnchor.constraint(equalToConstant: 10).isActive = true
                                imagePlay.tintColor = .white
                            }
                            titleReply.trailingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: -20).isActive = true
                            contentReply.trailingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: -20).isActive = true
                        }
                    }
                    if (attachment_flag == "11" && message_text.components(separatedBy: "/").count > 1) {
                        let imageSticker = UIImageView(image: UIImage(named: (message_text.component(1, separatedBy: "/")), in: Bundle.resourceBundle(for: Nexilis.self), with: nil))
                        containerReply.addSubview(imageSticker)
                        imageSticker.layer.cornerRadius = 2.0
                        imageSticker.clipsToBounds = true
                        imageSticker.translatesAutoresizingMaskIntoConstraints = false
                        imageSticker.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -10).isActive = true
                        imageSticker.centerYAnchor.constraint(equalTo: containerReply.centerYAnchor).isActive = true
                        imageSticker.widthAnchor.constraint(equalToConstant: 30).isActive = true
                        imageSticker.heightAnchor.constraint(equalToConstant: 30).isActive = true
                        titleReply.trailingAnchor.constraint(equalTo: imageSticker.leadingAnchor, constant: -20).isActive = true
                        contentReply.trailingAnchor.constraint(equalTo: imageSticker.leadingAnchor, constant: -20).isActive = true
                    }
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !data.isEmpty && data["read_receipts"] as? String == "8" && indexPath.section == 1 && indexPath.row <= dataLocation.count - 1 {
            if !isPersonal {
                if let latitude = CLLocationDegrees(dataStatus[indexPath.row]["latitude"] as? String ?? "") {
                    if let longitude = CLLocationDegrees(dataStatus[indexPath.row]["longitude"] as? String ?? "") {
                        openMapApp(latitude: latitude, longitude: longitude)
                    }
                }
            } else {
                if let latitude = CLLocationDegrees(dataStatus[0]["latitude"] as? String ?? "") {
                    if let longitude = CLLocationDegrees(dataStatus[0]["longitude"] as? String ?? "") {
                        openMapApp(latitude: latitude, longitude: longitude)
                    }
                }
            }
        }
    }
    
    func openMapApp(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let appleMapsURL = "http://maps.apple.com/?q=\(latitude),\(longitude)"
        let googleMapsURL = "comgooglemaps://?q=\(latitude),\(longitude)&zoom=14"
        
        if let googleMaps = URL(string: googleMapsURL), UIApplication.shared.canOpenURL(googleMaps) {
            UIApplication.shared.open(googleMaps, options: [:], completionHandler: nil)
        } else if let appleMaps = URL(string: appleMapsURL) {
            UIApplication.shared.open(appleMaps, options: [:], completionHandler: nil)
        } else {
            print("No map application available.")
        }
    }
    
    private func chatDate(stringDate: String) -> String {
        // Fix: force-unwrapped, on a value taken straight from the message row - a missing or
        // non-numeric server_date crashed the screen before it could draw anything.
        let date = Date(milliseconds: Int64(stringDate) ?? 0)
        let calendar = Calendar.current
        if (calendar.isDateInToday(date)) {
            return "Today".localized()
        } else {
            let startOfNow = calendar.startOfDay(for: Date())
            let startOfTimeStamp = calendar.startOfDay(for: date)
            let components = calendar.dateComponents([.day], from: startOfNow, to: startOfTimeStamp)
            let day = -(components.day ?? 0)
            if day == 1 {
                return "Yesterday".localized()
            } else if day < 7 {
                return "\(day) " + "days".localized() + " " + "ago".localized()
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = ChatDayLabel.format(for: date)
                let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
                if lang == "id" {
                    formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                }
                let stringFormat = formatter.string(from: date as Date)
                return stringFormat
            }
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }
    
    private func profileThumb(forPin pin: String) -> String {
        guard !pin.isEmpty else {
            return ""
        }
        return User.getData(pin: pin)?.thumb ?? ""
    }

    /// What a piece of audio says for itself when nothing can be done to it: how long it runs, and
    /// the shape of the sound. This screen is a record of what happened to a message, not a place
    /// to listen to it or open it, so nothing here responds to a touch.
    private func describeAudio(in content: AudioBubbleContent, named name: String) {
        content.isUserInteractionEnabled = false
        if let seconds = AudioDurationStore.seconds(forFileNamed: name) {
            content.timeLabel.text = String(format: "%d:%02d", seconds / 60, seconds % 60)
            content.slider.maximumValue = Float(seconds)
        }
        guard content.isVoiceNote else {
            return
        }
        if let known = AudioWaveformStore.levels(for: name) {
            content.wave.levels = known
            return
        }
        // Only the plain file is read. Decrypting one whole just to draw a line on a screen that
        // cannot play it is not work worth starting.
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let candidates = [documents.appendingPathComponent(name), caches.appendingPathComponent(name)]
        guard let url = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
            return
        }
        AudioWaveformStore.read(url: url, key: name) { [weak content] levels in
            content?.wave.levels = levels
        }
    }

    private func queryMessageReply(message_id: String) -> [String: Any?] {
        var dataQuery: [String: Any] = [:]
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "SELECT message_id, f_pin, message_text, attachment_flag, thumb_id, image_id, video_id, file_id, audio_id FROM MESSAGE where message_id='\(message_id)'"), c.next() {
                dataQuery["message_id"] = c.string(forColumnIndex: 0)
                dataQuery["f_pin"] = c.string(forColumnIndex: 1)
                dataQuery["message_text"] = c.string(forColumnIndex: 2)
                dataQuery["attachment_flag"] = c.string(forColumnIndex: 3)
                dataQuery["thumb_id"] = c.string(forColumnIndex: 4)
                dataQuery["image_id"] = c.string(forColumnIndex: 5)
                dataQuery["video_id"] = c.string(forColumnIndex: 6)
                dataQuery["file_id"] = c.string(forColumnIndex: 7)
                dataQuery["audio_id"] = c.string(forColumnIndex: 8)
                c.close()
            }
        })
        return dataQuery
    }
    
    private func getDataProfile(f_pin: String, message_id: String) -> [String: String]{
        var data: [String: String] = [:]
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || last_name, image_id from BUDDY where f_pin = '\(f_pin)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0)!.trimmingCharacters(in: .whitespacesAndNewlines)
                data["image_id"] = c.string(forColumnIndex: 1)!
                c.close()
            }
            else if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || last_name, thumb_id from GROUPZ_MEMBER where f_pin = '\(f_pin)' AND group_id = '\(dataGroup["group_id"]!!)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0)!.trimmingCharacters(in: .whitespacesAndNewlines)
                data["image_id"] = c.string(forColumnIndex: 1)!
                c.close()
            } else if let c = Database().getRecords(fmdb: fmdb, query: "select f_display_name from MESSAGE where message_id = '\(message_id)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0)!
                data["image_id"] = ""
                c.close()
            } else {
                data["name"] = "Unknown".localized()
            }
        })
        return data
    }
    
    @objc func tapMessageText(_ sender: ObjectGesture) {
        LinkOpener.open(urlString: sender.message_id)
    }

}

// Fix: the message and "Read more" share one label, so the read-more tap has to stand aside for
// a tap that landed on a mention - otherwise one touch does both.
extension MessageInfo: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer is ReadMoreTap, let label = gestureRecognizer.view as? UILabel else {
            return true
        }
        return LinkHighlighting.mentionPin(at: touch.location(in: label), in: label) == nil
    }
}
