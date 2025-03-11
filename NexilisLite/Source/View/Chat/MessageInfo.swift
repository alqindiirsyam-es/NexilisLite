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
    
    func offset() -> CGFloat{
        guard let fontSize = Int(SecureUserDefaults.shared.value(forKey: "font_size") ?? "0") else { return 0 }
        return CGFloat(fontSize)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Message Info".localized()
        view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.topItem?.backButtonTitle = "Back".localized()
        
        tableStatus = UITableView(frame: .zero, style: .grouped)
        tableStatus.register(UITableViewCell.self, forCellReuseIdentifier: "cellStatus")
        tableStatus.dataSource = self
        tableStatus.delegate = self
        tableStatus.separatorStyle = .none
        tableStatus.bounces = false
        
        getData()
        dateMessage = chatDate(stringDate: data["server_date"] as! String)
        
        tableStatus.reloadData()
        DispatchQueue.global().async{
            self.getAllLocationDesc()
        }
        
        view.addSubview(tableStatus)
        tableStatus.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor)
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
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_pin, status, time_delivered, time_read, time_ack, longitude, latitude FROM MESSAGE_STATUS where message_id='\(data["message_id"]!!)'") {
                    var listStatus: [Int] = []
                    while cursorData.next() {
                        var row: [String: Any?] = [:]
                        row["f_pin"] = cursorData.string(forColumnIndex: 0) ?? ""
                        row["status"] = cursorData.string(forColumnIndex: 1) ?? ""
                        row["time_delivered"] = cursorData.string(forColumnIndex: 2) ?? ""
                        row["time_read"] = cursorData.string(forColumnIndex: 3) ?? ""
                        row["time_ack"] = cursorData.string(forColumnIndex: 4) ?? ""
                        row["longitude"] = cursorData.string(forColumnIndex: 5) ?? ""
                        row["latitude"] = cursorData.string(forColumnIndex: 6) ?? ""
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
            let containerView = UIView()
            containerView.backgroundColor = .clear
            
            let dateView = UIView()
            containerView.addSubview(dateView)
            dateView.translatesAutoresizingMaskIntoConstraints = false
            var topAnchor = dateView.topAnchor.constraint(equalTo: containerView.topAnchor)
            if section == 0 {
                topAnchor = dateView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10.0)
            }
            NSLayoutConstraint.activate([
                topAnchor,
                dateView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                dateView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                dateView.heightAnchor.constraint(equalToConstant: 30),
                dateView.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
            ])
            dateView.backgroundColor = .orangeColor
            dateView.layer.cornerRadius = 15.0
            dateView.clipsToBounds = true
            
            let labelDate = UILabel()
            dateView.addSubview(labelDate)
            labelDate.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                labelDate.centerYAnchor.constraint(equalTo: dateView.centerYAnchor),
                labelDate.centerXAnchor.constraint(equalTo: dateView.centerXAnchor),
                labelDate.leadingAnchor.constraint(equalTo: dateView.leadingAnchor, constant: 10),
                labelDate.trailingAnchor.constraint(equalTo: dateView.trailingAnchor, constant: -10),
            ])
            labelDate.textAlignment = .center
            labelDate.textColor = .secondaryColor
            labelDate.font = UIFont.systemFont(ofSize: 12 + offset(), weight: .medium)
            labelDate.text = dateMessage
            return containerView
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
                            getImage(name: dataProfile["image_id"]!, placeholderImage: UIImage(named: "Profile---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                                content.image = image
                            })
                            
                            content.text = dataProfile["name"]!
                            if dataLocation.count > 0 {
                                content.text = dataProfile["name"]! + " at (\(dataLocation[indexPath.row]))"
                            }
                            
                            let date = Date(milliseconds: Int64(dataStatusAck[indexPath.row]["time_ack"] as! String) ?? 100)
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                            let time = formatter.string(from: date as Date)
                            
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
                            getImage(name: dataProfile["image_id"]!, placeholderImage: UIImage(named: "Profile---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                                content.image = image
                            })
                            
                            content.text = dataProfile["name"]!
                            
                            let date = Date(milliseconds: Int64(dataStatusRead[indexPath.row]["time_read"] as! String) ?? 100)
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                            let time = formatter.string(from: date as Date)
                            
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
                        getImage(name: dataProfile["image_id"]!, placeholderImage: UIImage(named: "Profile---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                            content.image = image
                        })
                        
                        content.text = dataProfile["name"]!
                        
                        let date = Date(milliseconds: Int64(dataStatusRead[indexPath.row]["time_read"] as! String) ?? 100)
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                        let time = formatter.string(from: date as Date)
                        
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
                        getImage(name: dataProfile["image_id"]!, placeholderImage: UIImage(named: "Profile---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                            content.image = image
                        })
                        
                        content.text = dataProfile["name"]!
                        
                        let date = Date(milliseconds: Int64(dataStatusDelivered[indexPath.row]["time_delivered"] as! String) ?? 100)
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                        let time = formatter.string(from: date as Date)
                        
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
                        if (dataStatus[0]["time_ack"] as! String).isEmpty {
                            cell.accessoryView = noStatus
                        } else {
                            let date = Date(milliseconds: Int64(dataStatus[0]["time_ack"] as! String) ?? 100)
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                            let time = formatter.string(from: date as Date)
                            
                            let viewTimeStatus = UIView()
                            viewTimeStatus.frame = CGRect(x: 0, y: 0, width: 80, height: cell.frame.height)
                            
                            let titleTime = UILabel()
                            viewTimeStatus.addSubview(titleTime)
                            titleTime.anchor(centerX: viewTimeStatus.centerXAnchor, centerY: viewTimeStatus.centerYAnchor)
                            titleTime.font = .systemFont(ofSize: 12 + offset())
                            titleTime.text = "\(chatDate(stringDate: dataStatus[0]["time_ack"] as! String)) \(time)"
                            
                            cell.accessoryView = viewTimeStatus
                        }
                    }
                } else {
                    content.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
                    content.text = "Read".localized()
                    if dataStatus.count != 0 {
                        if (dataStatus[0]["time_read"] as! String).isEmpty {
                            cell.accessoryView = noStatus
                        } else {
                            let date = Date(milliseconds: Int64(dataStatus[0]["time_read"] as! String) ?? 100)
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                            let time = formatter.string(from: date as Date)
                            
                            let viewTimeStatus = UIView()
                            viewTimeStatus.frame = CGRect(x: 0, y: 0, width: 80, height: cell.frame.height)
                            
                            let titleTime = UILabel()
                            viewTimeStatus.addSubview(titleTime)
                            titleTime.anchor(centerX: viewTimeStatus.centerXAnchor, centerY: viewTimeStatus.centerYAnchor)
                            titleTime.font = .systemFont(ofSize: 12 + offset())
                            titleTime.text = "\(chatDate(stringDate: dataStatus[0]["time_read"] as! String)) \(time)"
                            
                            cell.accessoryView = viewTimeStatus
                        }
                    }
                }
            } else if indexPath.row == 2 && !data.isEmpty && data["read_receipts"] as? String == "8" {
                content.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
                content.text = "Read".localized()
                if dataStatus.count != 0 {
                    if (dataStatus[0]["time_read"] as! String).isEmpty {
                        cell.accessoryView = noStatus
                    } else {
                        let date = Date(milliseconds: Int64(dataStatus[0]["time_read"] as! String) ?? 100)
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                        let time = formatter.string(from: date as Date)
                        
                        let viewTimeStatus = UIView()
                        viewTimeStatus.frame = CGRect(x: 0, y: 0, width: 80, height: cell.frame.height)
                        
                        let titleTime = UILabel()
                        viewTimeStatus.addSubview(titleTime)
                        titleTime.anchor(centerX: viewTimeStatus.centerXAnchor, centerY: viewTimeStatus.centerYAnchor)
                        titleTime.font = .systemFont(ofSize: 12 + offset())
                        titleTime.text = "\(chatDate(stringDate: dataStatus[0]["time_read"] as! String)) \(time)"
                        
                        cell.accessoryView = viewTimeStatus
                    }
                }
            } else {
                content.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
                content.text = "Delivered".localized()
                if (dataStatus[0]["time_delivered"] as! String).isEmpty {
                    cell.accessoryView = noStatus
                } else {
                    let date = Date(milliseconds: Int64(dataStatus[0]["time_delivered"] as! String) ?? 100)
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                    let time = formatter.string(from: date as Date)
                    
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
            let reffChat = (data["reff_id"] as? String) ?? ""
            
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            
            let containerMessage = UIView()
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
            
            timeMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            
            cell.contentView.addSubview(statusMessage)
            statusMessage.translatesAutoresizingMaskIntoConstraints = false
            statusMessage.bottomAnchor.constraint(equalTo: timeMessage.topAnchor).isActive = true
            statusMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            statusMessage.widthAnchor.constraint(equalToConstant: 15).isActive = true
            statusMessage.heightAnchor.constraint(equalToConstant: 15).isActive = true
            if (data["status"]! as! String == "1" || data["status"]! as! String == "2" ) {
                statusMessage.image = UIImage(named: "checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
            } else if (data["status"]! as! String == "3") {
                statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
            } else if (data["status"]! as! String == "8") {
                statusMessage.image = UIImage(named: "message_status_ack", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            } else {
                statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
            }
            
            if data["is_stared"] as? String == "1" {
                let imageStared = UIImageView()
                cell.contentView.addSubview(imageStared)
                imageStared.translatesAutoresizingMaskIntoConstraints = false
                imageStared.bottomAnchor.constraint(equalTo: statusMessage.topAnchor).isActive = true
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
                if data["attachment_flag"] as! String == "26" {
                    imageLS.image = UIImage(named: "pb_seminar_wpr", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                } else if data["attachment_flag"] as! String == "27" {
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
            
            let imageSticker = UIImageView()
            if let attachmentFlag = data["attachment_flag"], let attachmentFlag = attachmentFlag as? String {
                if attachmentFlag == "27" || attachmentFlag == "26" { // live streaming
                    let data = textChat
                    if let json = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                        Database().database?.inTransaction({ fmdb, rollback in
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
                    let data = textChat
                    if let json = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                        Database().database?.inTransaction({ fmdb, rollback in
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
                    var imageStickerBundle = UIImage(named: (textChat.components(separatedBy: "/")[1]), in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                    if imageStickerBundle == nil {
                        imageStickerBundle = UIImage(named: (textChat.components(separatedBy: "/")[1]), in: Bundle.resourcesMediaBundle(for: Nexilis.self), with: nil)
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
                    messageText.attributedText = textChat.richText()
                }
            } else {
                messageText.attributedText = textChat.richText()
            }
            
            let stringDate = (data["server_date"] as? String) ?? ""
            if !stringDate.isEmpty {
                let date = Date(milliseconds: Int64(stringDate) ?? 100)
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                timeMessage.text = formatter.string(from: date as Date)
                timeMessage.font = UIFont.systemFont(ofSize: 10 + offset(), weight: .medium)
                timeMessage.textColor = .lightGray
            }
            
            let imageThumb = UIImageView()
            let containerViewFile = UIView()
            
            if (!thumbChat.isEmpty) {
                let getHeightImage = ListGroupImages.getImageSize(image: thumbChat, screenWidth: self.view.frame.size.width * 0.6, screenHeight: 305)!.height
                let getWidthImage = ListGroupImages.getImageSize(image: thumbChat, screenWidth: self.view.frame.size.width * 0.6, screenHeight: 305)!.width
                topMarginText.constant = topMarginText.constant + (getHeightImage < 40 ? 40 : getHeightImage)
                
                containerMessage.addSubview(imageThumb)
                imageThumb.translatesAutoresizingMaskIntoConstraints = false
                let dataReply = queryMessageReply(message_id: reffChat)
                if (dataReply.count == 0) {
                    imageThumb.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
                }
                imageThumb.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                imageThumb.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                imageThumb.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                imageThumb.widthAnchor.constraint(equalToConstant: getWidthImage).isActive = true
                imageThumb.layer.cornerRadius = 5.0
                imageThumb.clipsToBounds = true
                imageThumb.contentMode = .scaleAspectFill
                
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
            
            if (fileChat != "") && data["message_scope_id"] as! String != "18" {
                topMarginText.constant = topMarginText.constant + 55
                
                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                let arrExtFile = (textChat.components(separatedBy: "|")[0]).split(separator: ".")
                let finalExtFile = arrExtFile[arrExtFile.count - 1]
                if let dirPath = paths.first {
                    let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(fileChat)
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
                    else if FileEncryption.shared.isSecureExists(filename: fileChat) {
                        if let dataFile = try? FileEncryption.shared.readSecure(filename: fileChat) {
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
                nameFile.text = textChat.components(separatedBy: "|")[0]
                
                if (data["progress"] as! Double != 100.0) {
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
            
            if (reffChat != "" && data["message_scope_id"] as! String != "18") {
                let dataReply = queryMessageReply(message_id: reffChat)
                if dataReply.count != 0 {
                    topMarginText.constant = topMarginText.constant + 55
                    
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
                    containerReply.heightAnchor.constraint(equalToConstant: 50).isActive = true
                    containerReply.backgroundColor = .black.withAlphaComponent(0.2)
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
                    if (data["f_pin"] as? String == idMe) {
                        titleReply.text = "You".localized()
                        if data["f_pin"] as? String == idMe {
                            titleReply.textColor = .white
                            leftReply.backgroundColor = .white
                        } else {
                            titleReply.textColor = .mainColor
                            leftReply.backgroundColor = .mainColor
                        }
                    } else {
                        titleReply.text = dataPerson["name"]!!
                        if data["f_pin"] as? String == idMe {
                            titleReply.textColor = .white
                            leftReply.backgroundColor = .white
                        }
                    }
                    
                    let contentReply = UILabel()
                    containerReply.addSubview(contentReply)
                    contentReply.translatesAutoresizingMaskIntoConstraints = false
                    contentReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
                    contentReply.bottomAnchor.constraint(equalTo: containerReply.bottomAnchor, constant: -10).isActive = true
                    contentReply.font = UIFont.systemFont(ofSize: 10 + offset())
                    let message_text = data["message_text"] as! String
                    let attachment_flag = data["attachment_flag"] as! String
                    let thumb_chat = data["thumb_id"] as! String
                    let image_chat = data["image_id"] as! String
                    let video_chat = data["video_id"] as! String
                    let file_chat = data["file_id"] as! String
                    if (attachment_flag == "0" && thumb_chat == "") {
                        contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                        contentReply.attributedText = message_text.richText()
                    } else if (attachment_flag == "1" || image_chat != "") {
                        if (message_text == "") {
                            contentReply.text = "📷 Photo".localized()
                        } else {
                            contentReply.attributedText = message_text.richText()
                        }
                    } else if (attachment_flag == "2" || video_chat != "") {
                        if (message_text == "") {
                            contentReply.text = "📹 Video".localized()
                        } else {
                            contentReply.attributedText = message_text.richText()
                        }
                    } else if (attachment_flag == "6" || file_chat != ""){
                        contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                        contentReply.text = "📄 \(message_text.components(separatedBy: "|")[0])"
                    } else if (attachment_flag == "11") {
                        contentReply.text = "❤️ Sticker"
                    }
                    contentReply.textColor = .white.withAlphaComponent(0.8)
                    
                    if (attachment_flag == "1" || attachment_flag == "2" || image_chat != "" || video_chat != "") {
                        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                        if let dirPath = paths.first {
                            let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(thumb_chat)
                            let image    = UIImage(contentsOfFile: thumbURL.path)
                            let imageThumb = UIImageView(image: image)
                            containerReply.addSubview(imageThumb)
                            imageThumb.layer.cornerRadius = 2.0
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
                        let imageSticker = UIImageView(image: UIImage(named: (message_text.components(separatedBy: "/")[1]), in: Bundle.resourceBundle(for: Nexilis.self), with: nil))
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
        if !data.isEmpty && data["read_receipts"] as? String == "8" {
            if !isPersonal {
                let latitude = CLLocationDegrees(dataStatus[indexPath.row]["latitude"] as? String ?? "")!
                let longitude = CLLocationDegrees(dataStatus[indexPath.row]["longitude"] as? String ?? "")!
                openMapApp(latitude: latitude, longitude: longitude)
            } else {
                let latitude = CLLocationDegrees(dataStatus[0]["latitude"] as? String ?? "")!
                let longitude = CLLocationDegrees(dataStatus[0]["longitude"] as? String ?? "")!
                openMapApp(latitude: latitude, longitude: longitude)
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
        let date = Date(milliseconds: Int64(stringDate)!)
        let calendar = Calendar.current
        if (calendar.isDateInToday(date)) {
            return "Today".localized()
        } else {
            let startOfNow = calendar.startOfDay(for: Date())
            let startOfTimeStamp = calendar.startOfDay(for: date)
            let components = calendar.dateComponents([.day], from: startOfNow, to: startOfTimeStamp)
            let day = -(components.day!)
            if day == 1 {
                return "Yesterday".localized()
            } else if day < 7 {
                return "\(day) " + "days".localized() + " " + "ago".localized()
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "EE, dd MMM"
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
    
    private func queryMessageReply(message_id: String) -> [String: Any?] {
        var dataQuery: [String: Any] = [:]
        Database().database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "SELECT message_id, f_pin, message_text, attachment_flag, thumb_id, image_id, video_id, file_id FROM MESSAGE where message_id='\(message_id)'"), c.next() {
                dataQuery["message_id"] = c.string(forColumnIndex: 0)
                dataQuery["f_pin"] = c.string(forColumnIndex: 1)
                dataQuery["message_text"] = c.string(forColumnIndex: 2)
                dataQuery["attachment_flag"] = c.string(forColumnIndex: 3)
                dataQuery["thumb_id"] = c.string(forColumnIndex: 4)
                dataQuery["image_id"] = c.string(forColumnIndex: 5)
                dataQuery["video_id"] = c.string(forColumnIndex: 6)
                dataQuery["file_id"] = c.string(forColumnIndex: 7)
                c.close()
            }
        })
        return dataQuery
    }
    
    private func getDataProfile(f_pin: String, message_id: String) -> [String: String]{
        var data: [String: String] = [:]
        Database().database?.inTransaction({ fmdb, rollback in
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
        var stringURl = sender.message_id.lowercased()
        if stringURl.starts(with: "www.") {
            stringURl = "https://" + stringURl.replacingOccurrences(of: "www.", with: "")
        }
        guard let url = URL(string: stringURl) else { return }
        UIApplication.shared.open(url)
    }

}
