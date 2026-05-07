//
//  BackupRestoreView.swift
//  NexilisLite
//
//  Created by Akhmad Al Qindi Irsyam on 16/02/23.
//

import UIKit
import QuickLook
//import Zip
import NotificationBannerSwift
import ZIPFoundation

public class BackupRestoreView: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private var tableView: UITableView!
    var centerLogo = UIImageView()
    var centerLogoIsRotated = false
    let activityIndicatorBackup = UIActivityIndicatorView(style: .medium)
    let activityIndicatorRestore = UIActivityIndicatorView(style: .medium)
    let titleBackup = UILabel()
    let titleRestore = UILabel()
    let titleLastBackup = UILabel()
    let titleTotalSize = UILabel()
    let labelRestoring = UILabel()
    let labelPreparing = UILabel()
    
    var isBackupStart = false
    var isRestoreStart = false
    
    var valueLastBackup = ""
    var valuesizeBackup = ""
    var dayLastBackup = ""
    var timeLastBackup = ""
    var choosenOption = "M"
    
    var fileIdBackup = ""
    var recordSizeBackup = ""
    var optionBackup = ""
    var recordSizeRestore: Int64 = 0
    
    let separator = String(unicodeCodepoint: 0x06) ?? ""

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.backButtonTitle = ""
        
        tableView = UITableView()
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellBackupRestore")
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.separatorStyle = .none
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(backupAvailability(notification:)), name: NSNotification.Name(rawValue: "backupAvailability"), object: nil)
        requestBackupAvailability()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.topItem?.title = "Backup & Restore".localized()
        self.navigationController?.navigationBar.setNeedsLayout()
        self.title = "Backup & Restore".localized()
    }
    
    @objc private func backupAvailability(notification: NSNotification) {
        DispatchQueue.main.async { [self] in
            let data:[AnyHashable : Any] = notification.userInfo!
            if let message = data["message"] as? TMessage {
                fileIdBackup = message.getBody(key: CoreMessage_TMessageKey.FILE_ID, default_value: "")
                recordSizeBackup = message.getBody(key: CoreMessage_TMessageKey.RECORD_SIZE, default_value: "0")
                optionBackup = message.getBody(key: CoreMessage_TMessageKey.TYPE, default_value: "")
                let filesize = message.getBody(key: CoreMessage_TMessageKey.FILE_SIZE, default_value: "0")
                let createdDate = message.getBody(key: CoreMessage_TMessageKey.CREATED_DATE, default_value: "\(Date().currentTimeMillis())")
                if optionBackup != "AUTO" {
                    let date = Date(milliseconds: Int64(createdDate)!)
                    let calendar = Calendar.current
                    
                    if (calendar.isDateInToday(date)) {
                        dayLastBackup = "Today".localized()
                    } else {
                        let startOfNow = calendar.startOfDay(for: Date())
                        let startOfTimeStamp = calendar.startOfDay(for: date)
                        let components = calendar.dateComponents([.day], from: startOfNow, to: startOfTimeStamp)
                        let day = -(components.day!)
                        if day == 1{
                            dayLastBackup = "Yesterday".localized()
                        } else {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "dd MMMM yyyy"
                            let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
                            if lang == "id" {
                                formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                            }
                            let stringFormat = formatter.string(from: date as Date)
                            dayLastBackup = stringFormat
                        }
                    }
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                    timeLastBackup = formatter.string(from: date as Date)
                    
                    valueLastBackup = dayLastBackup.localized() + ", " + timeLastBackup
                    valuesizeBackup = Units(bytes: Int64(filesize)!).getReadableUnit()
                    tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                } else {
                    valueLastBackup = "-"
                    valuesizeBackup = "-"
                    tableView.reloadRows(at: [IndexPath(row: 0, section: 0), IndexPath(row: 0, section: 2)], with: .none)
                }
            }
        }
    }
    
    private func requestBackupAvailability() {
        DispatchQueue.global().async {
            _ = Nexilis.write(message: CoreMessage_TMessageBank.getBackupAvailability())
        }
    }
    
    private func getFileName(option: String = "", fileId: String = "", withoutZIP: Bool = false) -> String {
        if !fileId.isEmpty {
            if withoutZIP {
                return "\(User.getMyPin()!)_\(option)_\(fileId)"
            }
            return "\(User.getMyPin()!)_\(option)_\(fileId).zip"
        }
        return "\(User.getMyPin()!)_\(option)_\(Date().currentTimeMillis())"
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 2 && isBackupStart {
            let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 20))
            container.addSubview(labelPreparing)
            labelPreparing.anchor(left: container.leftAnchor, paddingLeft: 10, centerY: container.centerYAnchor)
            labelPreparing.textColor = .gray
            labelPreparing.font = .systemFont(ofSize: 12)
            return container
        } else if section == 3 && isRestoreStart {
            let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 20))
            container.addSubview(labelRestoring)
            labelRestoring.anchor(left: container.leftAnchor, paddingLeft: 10, centerY: container.centerYAnchor)
            labelRestoring.textColor = .gray
            labelRestoring.font = .systemFont(ofSize: 12)
            return container
        }
        return UIView()
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 2 && isBackupStart {
            return 30
        } else if section == 3 && isRestoreStart {
            return 30
        }
        return 20
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 2
        } else if section == 3 {
            return 0
        }
        return 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellBackupRestore", for: indexPath as IndexPath)
        makeViewBackup(cell: cell, indexPath: indexPath)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 && indexPath.row == 0 {
            let controller = BackupRestoreOption()
            controller.selected = choosenOption
            controller.isSelected = { choosen in
                self.choosenOption = choosen
                tableView.reloadRows(at: [indexPath], with: .none)
            }
            navigationController?.show(controller, sender: nil)
        } else if indexPath.section == 1 && indexPath.row == 1 {
            if isBackupStart || isRestoreStart {
                return
            }
            if !CheckConnection.isConnectedToNetwork() {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            isBackupStart = true
            labelPreparing.text = "Preparing...".localized();
            tableView.reloadRows(at: [indexPath], with: .none)
            tableView.reloadSections(IndexSet(integer: 2), with: .none)
            animateBackup()
            DispatchQueue.global().async {
                self.backupData(indexPath: indexPath)
            }
        } else if indexPath.section == 2 {
            if isBackupStart || isRestoreStart || valueLastBackup == "-" {
                return
            }
            if !CheckConnection.isConnectedToNetwork() {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            isRestoreStart = true
            labelRestoring.text = "Downloading...".localized();
            tableView.reloadRows(at: [indexPath, IndexPath(row: 1, section: 1)], with: .none)
            tableView.reloadSections(IndexSet(integer: 3), with: .none)
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(getFileName(option: optionBackup, fileId: fileIdBackup))
                if FileEncryption.shared.isSecureExists(filename: getFileName(option: optionBackup, fileId: fileIdBackup)) {
                    do {
                        if var data = try FileEncryption.shared.readSecure(filename: getFileName(option: optionBackup, fileId: fileIdBackup)) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                            if dataDecrypt != nil {
                                data = dataDecrypt!
                            }
                            try data.write(to: fileURL)
                            DispatchQueue.global().async {
                                self.restoreData(file: fileURL, dirPath: dirPath, indexPath: indexPath)
                            }
                        }
                    } catch {
                        
                    }
                } else {
                    Download().startHTTP(forKey: getFileName(option: optionBackup, fileId: fileIdBackup), isBackup: true) { (name, progress) in
                        DispatchQueue.main.async { [self] in
                            guard progress == 100 else {
                                if progress != -100 {
                                    let formatter = NumberFormatter()
                                    formatter.minimumFractionDigits = 1
                                    formatter.maximumFractionDigits = 1
                                    
                                    var prog = ""
                                    if let formatted = formatter.string(from: NSNumber(value: progress)) {
                                        prog = formatted
                                    }
                                    labelRestoring.text = "Downloading...".localized() + "  \(prog)%"
                                } else {
                                    labelRestoring.text = "Failed Restored Data".localized()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                        self.isRestoreStart = false
                                        tableView.reloadRows(at: [indexPath, IndexPath(row: 1, section: 1), IndexPath(row: 0, section: 0), IndexPath(row: 0, section: 2)], with: .none)
                                        tableView.reloadSections(IndexSet(integer: 3), with: .none)
                                    })
                                }
                                return
                            }
                            labelRestoring.text = "Restoring...".localized()
                            if FileEncryption.shared.isSecureExists(filename: getFileName(option: optionBackup, fileId: fileIdBackup)) {
                                do {
                                    if var data = try FileEncryption.shared.readSecure(filename: getFileName(option: optionBackup, fileId: fileIdBackup)) {
                                        let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                        if dataDecrypt != nil {
                                            data = dataDecrypt!
                                        }
                                        try data.write(to: fileURL)
                                        DispatchQueue.global().async {
                                            self.restoreData(file: fileURL, dirPath: dirPath, indexPath: indexPath)
                                        }
                                    }
                                } catch {
                                    
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func animateBackup() {
        UIView.animate(withDuration: 2, animations: { [self] in
            centerLogo.transform = centerLogo.transform.rotated(by: .pi)
        })
        UIView.animate(withDuration: 2, animations: { [self] in
            centerLogo.transform = centerLogo.transform.rotated(by: .pi)
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [self] in
            if isBackupStart {
                animateBackup()
            }
        })
    }
    
    private func enableButtonBackup() {
        titleBackup.text = "Back Up Now".localized()
        titleBackup.textColor = .systemBlue
        activityIndicatorBackup.stopAnimating()
    }
    
    private func disableButtonBackup(isRestore: Bool = false) {
        titleBackup.textColor = .gray
        if !isRestore{
            titleBackup.text = "Backing Up...".localized()
            activityIndicatorBackup.startAnimating()
        }
    }
    
    private func enableButtonRestore() {
        titleRestore.text = "Restore Now".localized()
        titleRestore.textColor = .systemBlue
        activityIndicatorRestore.stopAnimating()
    }
    
    private func disableButtonRestore(isBackup: Bool = false) {
        titleRestore.textColor = .gray
        if !isBackup && !activityIndicatorRestore.isAnimating {
            titleRestore.text = "Restoring...".localized()
            activityIndicatorRestore.startAnimating()
        } else {
            titleRestore.text = "Restore Now".localized()
            activityIndicatorRestore.stopAnimating()
        }
    }
    
    private func makeViewBackup(cell: UITableViewCell, indexPath: IndexPath) {
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.backgroundColor = .clear
        if indexPath.section == 0 {
            cell.selectionStyle = .none
            let container = UIView()
            container.addTopBorder(with: .lightGray.withAlphaComponent(0.5), andWidth: 1)
            container.addBottomBorder(with: .lightGray.withAlphaComponent(0.5), andWidth: 1)
            let content = cell.contentView
            content.addSubview(container)
            container.anchor(top: content.topAnchor, left: content.leftAnchor, bottom: content.bottomAnchor, right: content.rightAnchor)
            
            let containerLogo = UIView()
            containerLogo.layer.borderWidth = 1
            containerLogo.layer.borderColor = UIColor.lightGray.cgColor
            containerLogo.layer.cornerRadius = 8
            containerLogo.clipsToBounds = true
            container.addSubview(containerLogo)
            containerLogo.anchor(top: container.topAnchor, left: container.leftAnchor, paddingTop: 10, paddingLeft: 10, width: 70, height: 70)
            
            let logo = UIImageView()
            logo.image = UIImage(systemName: "icloud")
            logo.contentMode = .scaleAspectFit
            logo.tintColor = .systemBlue
            containerLogo.addSubview(logo)
            logo.anchor(centerX: containerLogo.centerXAnchor, centerY: containerLogo.centerYAnchor, width: 60, height: 60)
            
            centerLogo.image = UIImage(systemName: "arrow.clockwise")
            centerLogo.contentMode = .scaleAspectFit
            centerLogo.tintColor = .systemBlue
            if !isBackupStart {
                if !centerLogoIsRotated{
                    centerLogoIsRotated = true
                    centerLogo.transform = centerLogo.transform.rotated(by: .pi / 2)
                    //print("LOHE \(centerLogo.transform)")
                }
            }
            logo.addSubview(centerLogo)
            centerLogo.anchor(top: logo.topAnchor, left: logo.leftAnchor, paddingTop: 22, paddingLeft: 23)
            
            container.addSubview(titleLastBackup)
            titleLastBackup.anchor(top: container.topAnchor, left: containerLogo.rightAnchor, paddingTop: 25, paddingLeft: 10)
            titleLastBackup.text = "Last Backup".localized() + ": " + valueLastBackup
            titleLastBackup.textColor = .gray
            titleLastBackup.font = .systemFont(ofSize: 12)
            
            container.addSubview(titleTotalSize)
            titleTotalSize.anchor(top: titleLastBackup.bottomAnchor, left: containerLogo.rightAnchor, paddingLeft: 10)
            titleTotalSize.text = "Total Size".localized() + ": " + valuesizeBackup
            titleTotalSize.textColor = .gray
            titleTotalSize.font = .systemFont(ofSize: 12)
            
            let descBackup = UILabel()
            container.addSubview(descBackup)
            descBackup.anchor(top: containerLogo.bottomAnchor, left: container.leftAnchor, bottom: container.bottomAnchor, right: container.rightAnchor, paddingTop: 2, paddingLeft: 10, paddingBottom: 10, paddingRight: 10)
            descBackup.text = "Back up your chat history to server so if you lose your phone or switch to a new one or logout your account, your chat history is safe. You can restore your chat history when you relogin your account.".localized()
            descBackup.numberOfLines = 0
            descBackup.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
            descBackup.font = .systemFont(ofSize: 12)
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let container = UIView()
                container.addTopBorder(with: .lightGray.withAlphaComponent(0.5), andWidth: 1)
                container.addBottomBorder(with: .lightGray.withAlphaComponent(0.5), andWidth: 0.5, x: 10)
                let content = cell.contentView
                content.addSubview(container)
                container.anchor(top: content.topAnchor, left: content.leftAnchor, bottom: content.bottomAnchor, right: content.rightAnchor)
                
                let titleBackupOption = UILabel()
                container.addSubview(titleBackupOption)
                titleBackupOption.anchor(left: container.leftAnchor, paddingLeft: 10, centerY: container.centerYAnchor)
                titleBackupOption.text = "Back Up Option".localized()
                titleBackupOption.textColor = .systemBlue
                titleBackupOption.font = .systemFont(ofSize: 14)
                
                let arrowRight = UIImageView()
                arrowRight.tintColor = .gray
                arrowRight.image = UIImage(systemName: "chevron.right")
                container.addSubview(arrowRight)
                arrowRight.anchor(right: container.rightAnchor, paddingRight: 10, centerY: container.centerYAnchor)
                
                let titleChoosenOption = UILabel()
                container.addSubview(titleChoosenOption)
                titleChoosenOption.anchor(right: arrowRight.leftAnchor, paddingRight: 10, centerY: container.centerYAnchor)
                titleChoosenOption.text = BackupRestoreOption().convertSelectedOptionWithCode(code: choosenOption)
                titleChoosenOption.textColor = .lightGray
                titleChoosenOption.font = .systemFont(ofSize: 14)
                
            } else {
                let container = UIView()
                container.addBottomBorder(with: .lightGray.withAlphaComponent(0.5), andWidth: 1)
                let content = cell.contentView
                content.addSubview(container)
                container.anchor(top: content.topAnchor, left: content.leftAnchor, bottom: content.bottomAnchor, right: content.rightAnchor)
                
                container.addSubview(titleBackup)
                titleBackup.anchor(left: container.leftAnchor, paddingLeft: 10, centerY: container.centerYAnchor)
                titleBackup.font = .systemFont(ofSize: 14)
                
                container.addSubview(activityIndicatorBackup)
                activityIndicatorBackup.anchor(right: container.rightAnchor, paddingRight: 10, centerY: container.centerYAnchor)
                
                if isBackupStart || isRestoreStart {
                    cell.selectionStyle = .none
                    disableButtonBackup(isRestore: isRestoreStart)
                } else {
                    cell.selectionStyle = .default
                    enableButtonBackup()
                }
            }
        } else {
            let container = UIView()
            container.addTopBorder(with: .lightGray.withAlphaComponent(0.5), andWidth: 1)
            container.addBottomBorder(with: .lightGray.withAlphaComponent(0.5), andWidth: 1)
            let content = cell.contentView
            content.addSubview(container)
            container.anchor(top: content.topAnchor, left: content.leftAnchor, bottom: content.bottomAnchor, right: content.rightAnchor)
            
            container.addSubview(titleRestore)
            titleRestore.anchor(left: container.leftAnchor, paddingLeft: 10, centerY: container.centerYAnchor)
            titleRestore.font = .systemFont(ofSize: 14)
            
            container.addSubview(activityIndicatorRestore)
            activityIndicatorRestore.anchor(right: container.rightAnchor, paddingRight: 10, centerY: container.centerYAnchor)
            
            if isBackupStart || isRestoreStart || valueLastBackup == "-" {
                cell.selectionStyle = .none
                disableButtonRestore(isBackup: isBackupStart || valueLastBackup == "-")
            } else {
                cell.selectionStyle = .default
                enableButtonRestore()
            }
        }
    }
    
    private func restoreMessage(nameColumn: [String], message: [String]) {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                var cValues: [String: Any] = [:]
                var columnNameMessage: [String] = []
                if let tableInfo = Database.shared.getRecords(fmdb: fmdb,query: "PRAGMA table_info(MESSAGE)") {
                    while tableInfo.next() {
                        columnNameMessage.append(tableInfo.string(forColumn: "name")!)
                    }
                    tableInfo.close()
                }
                for i in 0..<message.count {
                    if i > nameColumn.count - 1 {
                        continue
                    }
                    if columnNameMessage.contains(nameColumn[i]) {
                        cValues[nameColumn[i]] = message[i] == "<empty>" || message[i] == "null" ? "" : message[i]
                    }
                }
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE", cvalues: cValues, replace: true)
                recordSizeRestore += 1
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    private func restoreUcList(dataUcList: [String]) {
        if dataUcList.count < 2 {
            return
        }
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                var pin = dataUcList[0]
                var lastMessageId = ""
                if pin == User.getMyPin() {
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin, l_pin from MESSAGE where message_id = '\(dataUcList[1])'"), cursor.next() {
                        if cursor.next() {
                            let fPin = cursor.string(forColumnIndex: 0) ?? ""
                            let lPin = cursor.string(forColumnIndex: 1) ?? ""
                            if fPin == User.getMyPin() {
                                pin = lPin
                            } else {
                                pin = fPin
                            }
                        }
                        cursor.close()
                    }
                } else {
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select message_id from MESSAGE_SUMMARY where l_pin = '\(pin)'"), cursor.next() {
                        lastMessageId = cursor.string(forColumnIndex: 0) ?? ""
                    }
                }
                if lastMessageId.isEmpty && pin != User.getMyPin() {
                    _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                        "l_pin" : pin,
                        "message_id" : dataUcList[1],
                        "counter" : 0,
                        "pinned" : 0,
                        "archived" : 0
                    ], replace: true)
                }
                recordSizeRestore += 1
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    private func restoreFormData(nameColumn: [String], data: [String]) {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                var cValues: [String: Any] = [:]
                var columnNameMessage: [String] = []
                if let tableInfo = Database.shared.getRecords(fmdb: fmdb,query: "PRAGMA table_info(FORM_DATA)") {
                    while tableInfo.next() {
                        columnNameMessage.append(tableInfo.string(forColumn: "name")!)
                    }
                    tableInfo.close()
                }
                for i in 0..<data.count {
                    if columnNameMessage.contains(nameColumn[i]) {
                        cValues[nameColumn[i]] = data[i] == "<empty>" || data[i] == "null" ? "" : data[i]
                    }
                }
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "FORM_DATA", cvalues: cValues, replace: true)
                recordSizeRestore += 1
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    private func restoreTaskPIC(nameColumn: [String], data: [String]) {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                var cValues: [String: Any] = [:]
                var columnNameMessage: [String] = []
                if let tableInfo = Database.shared.getRecords(fmdb: fmdb,query: "PRAGMA table_info(TASK_PIC)") {
                    while tableInfo.next() {
                        columnNameMessage.append(tableInfo.string(forColumn: "name")!)
                    }
                    tableInfo.close()
                }
                for i in 0..<data.count {
                    if columnNameMessage.contains(nameColumn[i]) {
                        cValues[nameColumn[i]] = data[i] == "<empty>" || data[i] == "null" ? "" : data[i]
                    }
                }
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "TASK_PIC", cvalues: cValues, replace: true)
                recordSizeRestore += 1
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    private func restoreTaskDetail(nameColumn: [String], data: [String]) {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                var cValues: [String: Any] = [:]
                var columnNameMessage: [String] = []
                if let tableInfo = Database.shared.getRecords(fmdb: fmdb,query: "PRAGMA table_info(TASK_DETAIL)") {
                    while tableInfo.next() {
                        columnNameMessage.append(tableInfo.string(forColumn: "name")!)
                    }
                    tableInfo.close()
                }
                for i in 0..<data.count {
                    if columnNameMessage.contains(nameColumn[i]) {
                        cValues[nameColumn[i]] = data[i] == "<empty>" || data[i] == "null" ? "" : data[i]
                    }
                }
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "TASK_DETAIL", cvalues: cValues, replace: true)
                recordSizeRestore += 1
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    private func restoreMessageStatus(nameColumn: [String], message: [String]) {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                var cValues: [String: Any] = [:]
                var columnNameMessage: [String] = []
                if let tableInfo = Database.shared.getRecords(fmdb: fmdb,query: "PRAGMA table_info(MESSAGE_STATUS)") {
                    while tableInfo.next() {
                        columnNameMessage.append(tableInfo.string(forColumn: "name")!)
                    }
                    tableInfo.close()
                }
                for i in 0..<message.count {
                    if i > nameColumn.count - 1 {
                        continue
                    }
                    if columnNameMessage.contains(nameColumn[i]) {
                        cValues[nameColumn[i]] = message[i] == "<empty>" || message[i] == "null" ? "" : message[i]
                    }
                }
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: cValues, replace: true)
                recordSizeRestore += 1
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    private func restoreData(file: URL, dirPath: String, indexPath: IndexPath) {
        recordSizeRestore = 0
        let fileManager = FileManager()
        var destinationURL = URL(fileURLWithPath: dirPath)
        destinationURL.appendPathComponent("unzipItem\(Date().currentTimeMillis())")
        do {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: file, to: destinationURL)
            
            let files = try fileManager.contentsOfDirectory(at: destinationURL, includingPropertiesForKeys: nil)
            for fileURL in files {
                let nameFile = fileURL.deletingPathExtension().lastPathComponent
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let newFileURL = fileURL.deletingPathExtension().appendingPathExtension("txt")
                if !fileManager.fileExists(atPath: newFileURL.path) {
                    try fileManager.moveItem(at: fileURL, to: newFileURL)
                }
                guard let reader = LineReader(url: newFileURL) else { continue }
                var headerColumns:[String] = []
                var isHeader = true
                for line in reader {
                    if line.isEmpty { continue }
                    if isHeader {
                        headerColumns = line.components(separatedBy: separator)
                        isHeader = false
                        continue
                    }
                    var data = line.components(separatedBy: separator)
                    if data.count != headerColumns.count {
                        print("Column mismatch \(line)")
                        continue
                    }
                    if data == headerColumns {
                        continue
                    }
                    for i in 0..<data.count {
                        data[i] = data[i]
                            .replacingOccurrences(of: "<NL>", with: "\n")
                            .replacingOccurrences(of: "<CR>", with: "\r")
                    }
                    switch nameFile {

                    case "MESSAGE":
                        restoreMessage(nameColumn: headerColumns, message: data)
                    case "UC_LIST":
                        restoreUcList(dataUcList: data)
                    case "FORM_DATA":
                        restoreFormData(nameColumn: headerColumns, data: data)
                    case "TASK_PIC":
                        restoreTaskPIC(nameColumn: headerColumns, data: data)
                    case "TASK_DETAIL":
                        restoreTaskDetail(nameColumn: headerColumns, data: data)
                    case "MESSAGE_STATUS":
                        restoreMessageStatus(nameColumn: headerColumns, message: data)
                    default:
                        break
                    }
                    recordSizeRestore += 1
                    if recordSizeRestore % 100 == 0 {
                        let percent = formatPercentage(
                            numerator: recordSizeRestore,
                            denominator: Int64(recordSizeBackup) ?? 0
                        )
                        DispatchQueue.main.async {
                            if percent.replacingOccurrences(of: " ", with: " ") == "100,0 %" {
                                self.labelRestoring.text = "Finalizing data restore...".localized()
                            } else {
                                self.labelRestoring.text =
                                "Restoring...".localized() + " \(percent)"
                            }
                        }
                    }
                }
            }
            if recordSizeRestore < Int64(recordSizeBackup) ?? 0 {
                DispatchQueue.main.async { [self] in
                    labelRestoring.text = "Backup files are corrupted".localized()
                    tableView.reloadSections(IndexSet(integer: 3), with: .none)
                }
            } else {
                DispatchQueue.main.async { [self] in
                    labelRestoring.text = "Successfully Restored Data".localized()
                }
            }
//            DispatchQueue.global().async { [self] in
//                _ = Nexilis.write(message: CoreMessage_TMessageBank.getBackupRestored(option: optionBackup, fileid: fileIdBackup))
//            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [self] in
                isRestoreStart = false
                tableView.reloadRows(at: [indexPath, IndexPath(row: 1, section: 1), IndexPath(row: 0, section: 0), IndexPath(row: 0, section: 2)], with: .none)
                tableView.reloadSections(IndexSet(integer: 3), with: .none)
            })
        } catch {
            self.view.makeToast("Backup files are corrupted".localized(), duration: 3)
//            DispatchQueue.global().async { [self] in
//                _ = Nexilis.write(message: CoreMessage_TMessageBank.getBackupRestored(option: optionBackup, fileid: fileIdBackup))
//            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [self] in
                isRestoreStart = false
                tableView.reloadRows(at: [indexPath, IndexPath(row: 1, section: 1), IndexPath(row: 0, section: 0), IndexPath(row: 0, section: 2)], with: .none)
                tableView.reloadSections(IndexSet(integer: 3), with: .none)
            })
        }
    }
    
    private func backupData(indexPath: IndexPath) {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                let documentDirectoryUrl = try! FileManager.default.url(
                    for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
                )
                var recordSize: Int64 = 0
                
                //Make File MESSAGE
                let url_message = documentDirectoryUrl.appendingPathComponent("MESSAGE").appendingPathExtension("")
                FileManager.default.createFile(atPath: url_message.path, contents: nil)
                guard let file_message = try? FileHandle(forWritingTo: url_message) else { return }
                if let tableInfo = Database.shared.getRecords(fmdb: fmdb,query: "PRAGMA table_info(MESSAGE)") {
                    var columns: [String] = []
                    while tableInfo.next() {
                        columns.append(tableInfo.string(forColumn: "name")!)
                    }
                    let header = columns.joined(separator: separator) + "\n"
                    file_message.write(header.data(using: .utf8)!)
                    tableInfo.close()
                    
                    if let cursorData = Database.shared.getRecords(fmdb: fmdb,query: "SELECT * FROM MESSAGE") {
                        let columnCount = cursorData.columnCount
                        while cursorData.next() {
                            var line = ""
                            for i in 0..<columnCount {
                                if !line.isEmpty {
                                    line.append(separator)
                                }
                                let value = cursorData.string(forColumnIndex: i)
                                var text = toWrite(value)
                                text = text
                                    .replacingOccurrences(of: "\n", with: "<NL>")
                                    .replacingOccurrences(of: "\r", with: "<CR>")

                                line.append(text)
                            }
                            line.append("\n")
                            file_message.write(line.data(using: .utf8)!)
                            recordSize += 1
                        }
                        cursorData.close()
                    }
                    file_message.closeFile()
                }
                
                //Make File UC_LIST
                let url_uc_list = documentDirectoryUrl.appendingPathComponent("UC_LIST").appendingPathExtension("")
                FileManager.default.createFile(atPath: url_uc_list.path, contents: nil)
                guard let file_uc_list = try? FileHandle(forWritingTo: documentDirectoryUrl.appendingPathComponent("UC_LIST").appendingPathExtension("")) else { return }
                if let tableInfo = Database.shared.getRecords(fmdb: fmdb,query: "PRAGMA table_info(MESSAGE_SUMMARY)") {
                    var columns: [String] = []
                    while tableInfo.next() {
                        if tableInfo.string(forColumn: "name")! == "counter" {
                            continue
                        }
                        columns.append(tableInfo.string(forColumn: "name")! == "l_pin" ? "opposite" : tableInfo.string(forColumn: "name")!)
                    }
                    let header = columns.joined(separator: separator) + "\n"
                    file_uc_list.write(header.data(using: .utf8)!)
                    tableInfo.close()
                    
                    if let cursorData = Database.shared.getRecords(fmdb: fmdb,query: "SELECT * FROM MESSAGE_SUMMARY") {
                        let columnCount = cursorData.columnCount
                        while cursorData.next() {
                            var line = ""
                            for i in 0..<columnCount {
                                let columnName = cursorData.columnName(for: i)
                                if columnName == "counter" {
                                    continue
                                }
                                if !line.isEmpty {
                                    line.append(separator)
                                }
                                let value = cursorData.string(forColumnIndex: i)
                                var text = toWrite(value)
                                text = text
                                    .replacingOccurrences(of: "\n", with: "<NL>")
                                    .replacingOccurrences(of: "\r", with: "<CR>")

                                line.append(text)
                            }
                            line.append("\n")
                            file_uc_list.write(line.data(using: .utf8)!)
                            recordSize += 1
                        }
                        cursorData.close()
                    }
                    file_uc_list.closeFile()
                }
                
                //Make File FORM_DATA
                let url_form_data = documentDirectoryUrl.appendingPathComponent("FORM_DATA").appendingPathExtension("")
                FileManager.default.createFile(atPath: url_form_data.path, contents: nil)
                guard let file_form_data = try? FileHandle(forWritingTo: documentDirectoryUrl.appendingPathComponent("FORM_DATA").appendingPathExtension("")) else { return }
                if let tableInfo = Database.shared.getRecords(fmdb: fmdb,query: "PRAGMA table_info(FORM_DATA)") {
                    var columns: [String] = []
                    while tableInfo.next() {
                        columns.append(tableInfo.string(forColumn: "name")!)
                    }
                    let header = columns.joined(separator: separator) + "\n"
                    file_form_data.write(header.data(using: .utf8)!)
                    tableInfo.close()
                    
                    if let cursorData = Database.shared.getRecords(fmdb: fmdb,query: "SELECT * FROM FORM_DATA") {
                        let columnCount = cursorData.columnCount
                        while cursorData.next() {
                            var line = ""
                            for i in 0..<columnCount {
                                if !line.isEmpty {
                                    line.append(separator)
                                }
                                let value = cursorData.string(forColumnIndex: i)
                                var text = toWrite(value)
                                text = text
                                    .replacingOccurrences(of: "\n", with: "<NL>")
                                    .replacingOccurrences(of: "\r", with: "<CR>")

                                line.append(text)
                            }
                            line.append("\n")
                            file_form_data.write(line.data(using: .utf8)!)
                            recordSize += 1
                        }
                        cursorData.close()
                    }
                    file_form_data.closeFile()
                }
                
                //Make File TASK_PIC
                let url_task_pic = documentDirectoryUrl.appendingPathComponent("TASK_PIC").appendingPathExtension("")
                FileManager.default.createFile(atPath: url_task_pic.path, contents: nil)
                guard let file_task_pic = try? FileHandle(forWritingTo: documentDirectoryUrl.appendingPathComponent("TASK_PIC").appendingPathExtension("")) else { return }
                if let tableInfo = Database.shared.getRecords(fmdb: fmdb,query: "PRAGMA table_info(TASK_PIC)") {
                    var columns: [String] = []
                    while tableInfo.next() {
                        columns.append(tableInfo.string(forColumn: "name")!)
                    }
                    let header = columns.joined(separator: separator) + "\n"
                    file_task_pic.write(header.data(using: .utf8)!)
                    tableInfo.close()
                    
                    if let cursorData = Database.shared.getRecords(fmdb: fmdb,query: "SELECT * FROM TASK_PIC") {
                        let columnCount = cursorData.columnCount
                        while cursorData.next() {
                            var line = ""
                            for i in 0..<columnCount {
                                if !line.isEmpty {
                                    line.append(separator)
                                }
                                let value = cursorData.string(forColumnIndex: i)
                                var text = toWrite(value)
                                text = text
                                    .replacingOccurrences(of: "\n", with: "<NL>")
                                    .replacingOccurrences(of: "\r", with: "<CR>")

                                line.append(text)
                            }
                            line.append("\n")
                            file_task_pic.write(line.data(using: .utf8)!)
                            recordSize += 1
                        }
                        cursorData.close()
                    }
                    file_task_pic.closeFile()
                }
                
                //Make File TASK_DETAIL
                let url_task_detail = documentDirectoryUrl.appendingPathComponent("TASK_DETAIL").appendingPathExtension("")
                FileManager.default.createFile(atPath: url_task_detail.path, contents: nil)
                guard let file_task_detail = try? FileHandle(forWritingTo: documentDirectoryUrl.appendingPathComponent("TASK_DETAIL").appendingPathExtension("")) else { return }
                if let tableInfo = Database.shared.getRecords(fmdb: fmdb,query: "PRAGMA table_info(TASK_DETAIL)") {
                    var columns: [String] = []
                    while tableInfo.next() {
                        columns.append(tableInfo.string(forColumn: "name")!)
                    }
                    let header = columns.joined(separator: separator) + "\n"
                    file_task_detail.write(header.data(using: .utf8)!)
                    tableInfo.close()
                    
                    if let cursorData = Database.shared.getRecords(fmdb: fmdb,query: "SELECT * FROM TASK_DETAIL") {
                        let columnCount = cursorData.columnCount
                        while cursorData.next() {
                            var line = ""
                            for i in 0..<columnCount {
                                if !line.isEmpty {
                                    line.append(separator)
                                }
                                let value = cursorData.string(forColumnIndex: i)
                                var text = toWrite(value)
                                text = text
                                    .replacingOccurrences(of: "\n", with: "<NL>")
                                    .replacingOccurrences(of: "\r", with: "<CR>")

                                line.append(text)
                            }
                            line.append("\n")
                            file_task_detail.write(line.data(using: .utf8)!)
                            recordSize += 1
                        }
                        cursorData.close()
                    }
                    file_task_detail.closeFile()
                }
                
                //Make File MESSAGE_STATUS
                let url_task_status = documentDirectoryUrl.appendingPathComponent("MESSAGE_STATUS").appendingPathExtension("")
                FileManager.default.createFile(atPath: url_task_status.path, contents: nil)
                guard let file_task_status = try? FileHandle(forWritingTo: documentDirectoryUrl.appendingPathComponent("MESSAGE_STATUS").appendingPathExtension("")) else { return }
                if let tableInfo = Database.shared.getRecords(fmdb: fmdb,query: "PRAGMA table_info(MESSAGE_STATUS)") {
                    var columns: [String] = []
                    while tableInfo.next() {
                        columns.append(tableInfo.string(forColumn: "name")!)
                    }
                    let header = columns.joined(separator: separator) + "\n"
                    file_task_status.write(header.data(using: .utf8)!)
                    tableInfo.close()
                    
                    if let cursorData = Database.shared.getRecords(fmdb: fmdb,query: "SELECT * FROM MESSAGE_STATUS") {
                        let columnCount = cursorData.columnCount
                        while cursorData.next() {
                            var line = ""
                            for i in 0..<columnCount {
                                if !line.isEmpty {
                                    line.append(separator)
                                }
                                let value = cursorData.string(forColumnIndex: i)
                                var text = toWrite(value)
                                text = text
                                    .replacingOccurrences(of: "\n", with: "<NL>")
                                    .replacingOccurrences(of: "\r", with: "<CR>")

                                line.append(text)
                            }
                            line.append("\n")
                            file_task_status.write(line.data(using: .utf8)!)
                            recordSize += 1
                        }
                        cursorData.close()
                    }
                    file_task_status.closeFile()
                }
                
                //ZIP ALL FILES
                let fileManager = FileManager()
                var destinationURL = documentDirectoryUrl
                destinationURL.appendPathComponent("zipItem\(Date().currentTimeMillis())")
    //            let listFiles: [URL] = [file_message, file_uc_list, file_form_data, file_task_pic, file_task_detail]
                do {
                    try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
                    let nameZip = getFileName(option: choosenOption, fileId: "", withoutZIP: true)
                    let zipFiles = destinationURL.appendingPathComponent(nameZip).appendingPathExtension("zip")
    //                try Zip.zipFiles(paths: listFiles, zipFilePath: zipFiles, password: nil, progress: {progress in
    //                    self.labelPreparing.text = "Preparing...".localized() + " \(progress * 100)%"
    //                })
                    let unzipProgress = Progress()
                    let _ = unzipProgress.observe(\.fractionCompleted) { progress, _ in
                        DispatchQueue.main.async {
                            self.labelPreparing.text = "Preparing...".localized() + " \(progress.fractionCompleted * 100)%"
                        }
                    }
                    try fileManager.zipItem(at: url_message, to: zipFiles, progress: unzipProgress)
                    guard let archive = Archive(url: zipFiles, accessMode: .update) else  {
                        print("Failed Archive")
                        return
                    }
                    do {
                        try archive.addEntry(with: url_uc_list.lastPathComponent, relativeTo: url_uc_list.deletingLastPathComponent())
                        try archive.addEntry(with: url_form_data.lastPathComponent, relativeTo: url_form_data.deletingLastPathComponent())
                        try archive.addEntry(with: url_task_pic.lastPathComponent, relativeTo: url_task_pic.deletingLastPathComponent())
                        try archive.addEntry(with: url_task_detail.lastPathComponent, relativeTo: url_task_detail.deletingLastPathComponent())
                        try archive.addEntry(with: url_task_status.lastPathComponent, relativeTo: url_task_status.deletingLastPathComponent())
                    } catch {
                        print("Adding entry to ZIP archive failed with error:\(error)")
                    }
                    DispatchQueue.main.async {
                        self.labelPreparing.text = "Uploading...".localized()
                    }
                    Network().uploadHTTP(fileUrl: zipFiles, completion: { result,progress in
                        if result {
                            DispatchQueue.main.async { [self] in
                                let formatter = NumberFormatter()
                                formatter.minimumFractionDigits = 1
                                formatter.maximumFractionDigits = 1
                                
                                var prog = ""
                                if let formatted = formatter.string(from: NSNumber(value: progress)) {
                                    prog = formatted
                                }
                                labelPreparing.text = "Uploading...".localized() + " \(prog.isEmpty ? "\(progress)" : prog)%"
                                if progress == 100 {
                                    do {
                                        let path = zipFiles.path
                                        let attrib = try FileManager.default.attributesOfItem(atPath: path)
                                        let fileSize = attrib[.size] as! Int64
                                        DispatchQueue.global().async { [self] in
                                            _ = Nexilis.write(message: CoreMessage_TMessageBank.getBackupUploaded(option: choosenOption, fileid: nameZip.components(separatedBy: "_")[2], filesize: String(fileSize), recordSize: String(recordSize)))
                                        }
                                        let date = Date()
                                        let calendar = Calendar.current
                                        
                                        if (calendar.isDateInToday(date)) {
                                            dayLastBackup = "Today".localized()
                                        } else {
                                            let startOfNow = calendar.startOfDay(for: Date())
                                            let startOfTimeStamp = calendar.startOfDay(for: date)
                                            let components = calendar.dateComponents([.day], from: startOfNow, to: startOfTimeStamp)
                                            let day = -(components.day!)
                                            if day == 1{
                                                dayLastBackup = "Yesterday".localized()
                                            } else {
                                                let formatter = DateFormatter()
                                                formatter.dateFormat = "dd MMMM yyyy"
                                                let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
                                                if lang == "id" {
                                                    formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                                                }
                                                let stringFormat = formatter.string(from: date as Date)
                                                dayLastBackup = stringFormat
                                            }
                                        }
                                        
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "HH:mm"
                                        formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                                        timeLastBackup = formatter.string(from: date as Date)
                                        
                                        valueLastBackup = dayLastBackup.localized() + ", " + timeLastBackup
                                        valuesizeBackup = Units(bytes: fileSize).getReadableUnit()
                                        
                                        do {
                                            try FileEncryption.shared.writeSecure(filename: getFileName(option: optionBackup, fileId: fileIdBackup), data: Data(contentsOf: zipFiles))
                                            try FileManager.default.removeItem(atPath: zipFiles.path)
                                        } catch {
                                            
                                        }
                                        
                                        labelPreparing.text = "Successfully Backup Data".localized()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [self] in
                                            isBackupStart = false
                                            tableView.reloadRows(at: [indexPath, IndexPath(row: 0, section: 0)], with: .none)
                                            tableView.reloadSections(IndexSet(integer: 2), with: .none)
                                        })
                                    } catch {}
                                }
                            }
                        }  else {
                            DispatchQueue.main.async { [self] in
                                labelPreparing.text = "Failed Upload Backup Data".localized()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [self] in
                                    isBackupStart = false
                                    tableView.reloadRows(at: [indexPath, IndexPath(row: 0, section: 0)], with: .none)
                                    tableView.reloadSections(IndexSet(integer: 2), with: .none)
                                })
                            }
                        }
                    })
                } catch {
                    //print(error)
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }

}

func toWrite(_ value: String?) -> String {

    guard let v = value else {
        return "null"
    }

    if v.isEmpty {
        return "<empty>"
    }

    return v
}

func formatPercentage(numerator: Int64, denominator: Int64) -> String {
    guard denominator != 0 else { return "NaN" }

    var value = Double(numerator) / Double(denominator)
    value = min(value, 1.0)

    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.minimumFractionDigits = 1
    formatter.maximumFractionDigits = 1
    formatter.locale = Locale(identifier: "fr_FR") // uses comma as decimal separator

    return formatter.string(from: NSNumber(value: value)) ?? "NaN"
}

extension String {
    func appendLineToURL(fileURL: URL) throws {
         try (self + "\n").appendToURL(fileURL: fileURL)
     }

     func appendToURL(fileURL: URL) throws {
         let data = self.data(using: String.Encoding.utf8)!
         try data.append(fileURL: fileURL)
     }
 }

 extension Data {
     func append(fileURL: URL) throws {
         if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
             defer {
                 fileHandle.closeFile()
             }
             fileHandle.seekToEndOfFile()
             fileHandle.write(self)
         }
         else {
             try write(to: fileURL, options: .atomic)
         }
     }
 }

class LineReader: Sequence, IteratorProtocol {

    private let file: UnsafeMutablePointer<FILE>!

    init?(url: URL) {
        file = fopen(url.path, "r")
        if file == nil { return nil }
    }

    deinit {
        fclose(file)
    }

    func next() -> String? {

        var line: UnsafeMutablePointer<CChar>? = nil
        var linecap: Int = 0

        defer { free(line) }

        if getline(&line, &linecap, file) > 0 {
            return String(cString: line!).trimmingCharacters(in: .newlines)
        }

        return nil
    }
}
