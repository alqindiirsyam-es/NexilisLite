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
        
        navigationController?.navigationBar.topItem?.backButtonTitle = "Back".localized()
        
        tableView = UITableView()
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
                    
                    tableView.beginUpdates()
                    tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                    tableView.endUpdates()
                } else {
                    valueLastBackup = "-"
                    valuesizeBackup = "-"
                    tableView.beginUpdates()
                    tableView.reloadRows(at: [IndexPath(row: 0, section: 0), IndexPath(row: 0, section: 2)], with: .none)
                    tableView.endUpdates()
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
        return "\(User.getMyPin()!).zip"
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
                tableView.beginUpdates()
                tableView.reloadRows(at: [indexPath], with: .none)
                tableView.endUpdates()
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
            tableView.beginUpdates()
            tableView.reloadRows(at: [indexPath], with: .none)
            tableView.reloadSections(IndexSet(integer: 2), with: .none)
            tableView.endUpdates()
            animateBackup()
            backupData(indexPath: indexPath)
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
            tableView.beginUpdates()
            tableView.reloadRows(at: [indexPath, IndexPath(row: 1, section: 1)], with: .none)
            tableView.reloadSections(IndexSet(integer: 3), with: .none)
            tableView.endUpdates()
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(getFileName(option: optionBackup, fileId: fileIdBackup))
                if !FileManager.default.fileExists(atPath: fileURL.path) {
                    Download().startHTTP(forKey: getFileName(option: optionBackup, fileId: fileIdBackup), isImage: false) { (name, progress) in
                        DispatchQueue.main.async { [self] in
                            guard progress == 100 else {
                                labelRestoring.text = "Downloading...".localized() + "  \(progress)%"
                                return
                            }
                            labelRestoring.text = "Restoring...".localized()
                            restoreData(file: fileURL, dirPath: dirPath, indexPath: indexPath)
                        }
                    }
                } else {
                    labelRestoring.text = "Restoring...".localized()
                    restoreData(file: fileURL, dirPath: dirPath, indexPath: indexPath)
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
                if !(cValues["thumb_id"] as? String ?? "").isEmpty {
                    let thumbId = cValues["thumb_id"] as! String
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if let dirPath = paths.first {
                        let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(thumbId)
                        if !FileManager.default.fileExists(atPath: thumbURL.path) {
                            Download().startHTTP(forKey: thumbId) { (name, progress) in}
                        }
                    }
                }
                recordSizeRestore += 1
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    private func restoreUcList(dataUcList: [String]) {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                    "l_pin" : dataUcList[0],
                    "message_id" : dataUcList[1],
                    "counter" : 0
                ], replace: true)
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
    
    private func restoreData(file: URL, dirPath: String, indexPath: IndexPath) {
        recordSizeRestore = 0
        let fileManager = FileManager()
        var destinationURL = URL(fileURLWithPath: dirPath)
        destinationURL.appendPathComponent("unzipItem\(Date().currentTimeMillis())")
        do {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
//            try Zip.unzipFile(file, destination: destinationURL, overwrite: true, password: nil)
            try fileManager.unzipItem(at: file, to: destinationURL)
            
            let files = try FileManager.default.contentsOfDirectory(atPath: destinationURL.path)
            for file in files {
                let nameFile = (file as NSString).lastPathComponent
                let fileURL = destinationURL.appendingPathComponent(nameFile)
                var newFileExt: URL?
                newFileExt = fileURL.deletingPathExtension().appendingPathExtension("txt")
                try FileManager.default.moveItem(at: fileURL, to: newFileExt!)
                var textReading = try String(contentsOf: newFileExt ?? fileURL, encoding: .utf8)
                textReading = textReading.replacingOccurrences(of: "<NL>", with: "\n").replacingOccurrences(of: "<CR>", with: "\r")
                let valueText = textReading.components(separatedBy: "\n")
                if nameFile.trimmingCharacters(in: .whitespacesAndNewlines) == "MESSAGE" {
                    let nameColumn = valueText[0].components(separatedBy: separator)
                    for i in 1..<valueText.count - 1 {
                        let dataMessage = valueText[i].components(separatedBy: separator)
                        restoreMessage(nameColumn: nameColumn, message: dataMessage)
                    }
                } else if nameFile.trimmingCharacters(in: .whitespacesAndNewlines) == "UC_LIST" {
                    for i in 1..<valueText.count - 1 {
                        let dataUcList = valueText[i].components(separatedBy: separator)
                        restoreUcList(dataUcList: dataUcList)
                    }
                } else if nameFile.trimmingCharacters(in: .whitespacesAndNewlines) == "FORM_DATA" {
                    let nameColumn = valueText[0].components(separatedBy: separator)
                    for i in 1..<valueText.count - 1 {
                        let dataFormData = valueText[i].components(separatedBy: separator)
                        restoreFormData(nameColumn: nameColumn, data: dataFormData)
                    }
                } else if nameFile.trimmingCharacters(in: .whitespacesAndNewlines) == "TASK_PIC" {
                    let nameColumn = valueText[0].components(separatedBy: separator)
                    for i in 1..<valueText.count - 1 {
                        let dataTaskPIC = valueText[i].components(separatedBy: separator)
                        restoreTaskPIC(nameColumn: nameColumn, data: dataTaskPIC)
                    }
                }
                else if nameFile.trimmingCharacters(in: .whitespacesAndNewlines) == "TASK_DETAIL" {
                    let nameColumn = valueText[0].components(separatedBy: separator)
                    for i in 1..<valueText.count - 1 {
                        let dataTaskDetail = valueText[i].components(separatedBy: separator)
                        restoreTaskDetail(nameColumn: nameColumn, data: dataTaskDetail)
                    }
                }
            }
            if recordSizeRestore < Int64(recordSizeBackup) ?? 0 {
                labelRestoring.text = "Backup files are corrupted".localized()
                tableView.reloadSections(IndexSet(integer: 3), with: .none)
            } else {
                labelRestoring.text = "Successfully Restored Data".localized()
            }
//            DispatchQueue.global().async { [self] in
//                _ = Nexilis.write(message: CoreMessage_TMessageBank.getBackupRestored(option: optionBackup, fileid: fileIdBackup))
//            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [self] in
                isRestoreStart = false
                valueLastBackup = "-"
                valuesizeBackup = "-"
                tableView.beginUpdates()
                tableView.reloadRows(at: [indexPath, IndexPath(row: 1, section: 1), IndexPath(row: 0, section: 0), IndexPath(row: 0, section: 2)], with: .none)
                tableView.reloadSections(IndexSet(integer: 3), with: .none)
                tableView.endUpdates()
            })
        } catch {
            //print(error)
            self.view.makeToast("Backup files are corrupted".localized(), duration: 3)
//            DispatchQueue.global().async { [self] in
//                _ = Nexilis.write(message: CoreMessage_TMessageBank.getBackupRestored(option: optionBackup, fileid: fileIdBackup))
//            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [self] in
                isRestoreStart = false
                valueLastBackup = "-"
                valuesizeBackup = "-"
                tableView.beginUpdates()
                tableView.reloadRows(at: [indexPath, IndexPath(row: 1, section: 1), IndexPath(row: 0, section: 0), IndexPath(row: 0, section: 2)], with: .none)
                tableView.reloadSections(IndexSet(integer: 3), with: .none)
                tableView.endUpdates()
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
                let file_message = documentDirectoryUrl.appendingPathComponent("MESSAGE").appendingPathExtension("")
                if let tableInfo = Database.shared.getRecords(fmdb: fmdb,query: "PRAGMA table_info(MESSAGE)") {
                    var text_message = ""
                    while tableInfo.next() {
                        if text_message.isEmpty {
                            text_message.append(tableInfo.string(forColumn: "name")!)
                        } else {
                            text_message.append(separator)
                            text_message.append(tableInfo.string(forColumn: "name")!)
                        }
                    }
                    text_message.append("\n")
                    tableInfo.close()
                    
                    if let cursorData = Database.shared.getRecords(fmdb: fmdb,query: "SELECT * FROM MESSAGE") {
                        let columnCount = cursorData.columnCount
                        var value_m = ""
                        while cursorData.next() {
                            for i in 0..<columnCount {
                                value_m.append(cursorData.string(forColumnIndex: i) == nil ? "null" : cursorData.string(forColumnIndex: i)!.isEmpty ? "<empty>" : cursorData.string(forColumnIndex: i)!)
                                value_m.append(separator)
                            }
                            value_m.append("\n")
                            recordSize += 1
                        }
                        text_message.append(value_m)
                        cursorData.close()
                    }
                    do {
                        try text_message.write(to: file_message, atomically: true, encoding: .utf8)
                    }
                    catch {
                        //print(error)
                    }
                }
                
                //Make File UC_LIST
                let file_uc_list = documentDirectoryUrl.appendingPathComponent("UC_LIST").appendingPathExtension("")
                if let tableInfo = Database.shared.getRecords(fmdb: fmdb,query: "PRAGMA table_info(MESSAGE_SUMMARY)") {
                    var text_uc_list = ""
                    while tableInfo.next() {
                        if tableInfo.string(forColumn: "name")! == "counter" {
                            continue
                        }
                        if text_uc_list.isEmpty {
                            text_uc_list.append(tableInfo.string(forColumn: "name")! == "l_pin" ? "opposite" : tableInfo.string(forColumn: "name")!)
                        } else {
                            text_uc_list.append(separator)
                            text_uc_list.append(tableInfo.string(forColumn: "name")! == "l_pin" ? "opposite" : tableInfo.string(forColumn: "name")!)
                        }
                    }
                    text_uc_list.append("\n")
                    tableInfo.close()
                    
                    if let cursorData = Database.shared.getRecords(fmdb: fmdb,query: "SELECT * FROM MESSAGE_SUMMARY") {
                        let columnCount = cursorData.columnCount
                        var value_m = ""
                        while cursorData.next() {
                            for i in 0..<columnCount - 1 {
                                value_m.append(cursorData.string(forColumnIndex: i) == nil ? "null" : cursorData.string(forColumnIndex: i)!.isEmpty ? "<empty>" : cursorData.string(forColumnIndex: i)!)
                                value_m.append(separator)
                            }
                            value_m.append("\n")
                            recordSize += 1
                        }
                        text_uc_list.append(value_m)
                        cursorData.close()
                    }
                    do {
                        try text_uc_list.write(to: file_uc_list, atomically: true, encoding: .utf8)
                    }
                    catch {//print(error)
                        
                    }
                }
                
                //Make File FORM_DATA
                let file_form_data = documentDirectoryUrl.appendingPathComponent("FORM_DATA").appendingPathExtension("")
                if let tableInfo = Database.shared.getRecords(fmdb: fmdb,query: "PRAGMA table_info(FORM_DATA)") {
                    var text_form_data = ""
                    while tableInfo.next() {
                        if text_form_data.isEmpty {
                            text_form_data.append(tableInfo.string(forColumn: "name")!)
                        } else {
                            text_form_data.append(separator)
                            text_form_data.append(tableInfo.string(forColumn: "name")!)
                        }
                    }
                    text_form_data.append("\n")
                    tableInfo.close()
                    
                    if let cursorData = Database.shared.getRecords(fmdb: fmdb,query: "SELECT * FROM FORM_DATA") {
                        let columnCount = cursorData.columnCount
                        var value_m = ""
                        while cursorData.next() {
                            for i in 0..<columnCount - 1 {
                                value_m.append(cursorData.string(forColumnIndex: i) == nil ? "null" : cursorData.string(forColumnIndex: i)!.isEmpty ? "<empty>" : cursorData.string(forColumnIndex: i)!)
                                value_m.append(separator)
                            }
                            value_m.append("\n")
                            recordSize += 1
                        }
                        text_form_data.append(value_m)
                        cursorData.close()
                    }
                    do {
                        try text_form_data.write(to: file_form_data, atomically: true, encoding: .utf8)
                    }
                    catch {//print(error)
                        
                    }
                }
                
                //Make File TASK_PIC
                let file_task_pic = documentDirectoryUrl.appendingPathComponent("TASK_PIC").appendingPathExtension("")
                if let tableInfo = Database.shared.getRecords(fmdb: fmdb,query: "PRAGMA table_info(TASK_PIC)") {
                    var text_task_pic = ""
                    while tableInfo.next() {
                        if text_task_pic.isEmpty {
                            text_task_pic.append(tableInfo.string(forColumn: "name")!)
                        } else {
                            text_task_pic.append(separator)
                            text_task_pic.append(tableInfo.string(forColumn: "name")!)
                        }
                    }
                    text_task_pic.append("\n")
                    tableInfo.close()
                    
                    if let cursorData = Database.shared.getRecords(fmdb: fmdb,query: "SELECT * FROM TASK_PIC") {
                        let columnCount = cursorData.columnCount
                        var value_m = ""
                        while cursorData.next() {
                            for i in 0..<columnCount - 1 {
                                value_m.append(cursorData.string(forColumnIndex: i) == nil ? "null" : cursorData.string(forColumnIndex: i)!.isEmpty ? "<empty>" : cursorData.string(forColumnIndex: i)!)
                                value_m.append(separator)
                            }
                            value_m.append("\n")
                            recordSize += 1
                        }
                        text_task_pic.append(value_m)
                        cursorData.close()
                    }
                    do {
                        try text_task_pic.write(to: file_task_pic, atomically: true, encoding: .utf8)
                    }
                    catch {//print(error)
                        
                    }
                }
                
                //Make File TASK_DETAIL
                let file_task_detail = documentDirectoryUrl.appendingPathComponent("TASK_DETAIL").appendingPathExtension("")
                if let tableInfo = Database.shared.getRecords(fmdb: fmdb,query: "PRAGMA table_info(TASK_DETAIL)") {
                    var text_task_detail = ""
                    while tableInfo.next() {
                        if text_task_detail.isEmpty {
                            text_task_detail.append(tableInfo.string(forColumn: "name")!)
                        } else {
                            text_task_detail.append(separator)
                            text_task_detail.append(tableInfo.string(forColumn: "name")!)
                        }
                    }
                    text_task_detail.append("\n")
                    tableInfo.close()
                    
                    if let cursorData = Database.shared.getRecords(fmdb: fmdb,query: "SELECT * FROM TASK_DETAIL") {
                        let columnCount = cursorData.columnCount
                        var value_m = ""
                        while cursorData.next() {
                            for i in 0..<columnCount - 1 {
                                value_m.append(cursorData.string(forColumnIndex: i) == nil ? "null" : cursorData.string(forColumnIndex: i)!.isEmpty ? "<empty>" : cursorData.string(forColumnIndex: i)!)
                                value_m.append(separator)
                            }
                            value_m.append("\n")
                            recordSize += 1
                        }
                        text_task_detail.append(value_m)
                        cursorData.close()
                    }
                    do {
                        try text_task_detail.write(to: file_task_detail, atomically: true, encoding: .utf8)
                    }
                    catch {//print(error)
                        
                    }
                }
                
                //ZIP ALL FILES
                let fileManager = FileManager()
                var destinationURL = documentDirectoryUrl
                destinationURL.appendPathComponent("zipItem\(Date().currentTimeMillis())")
    //            let listFiles: [URL] = [file_message, file_uc_list, file_form_data, file_task_pic, file_task_detail]
                do {
                    try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
                    let zipFiles = destinationURL.appendingPathComponent(getFileName(option: choosenOption, fileId: fileIdBackup, withoutZIP: true)).appendingPathExtension("zip")
    //                try Zip.zipFiles(paths: listFiles, zipFilePath: zipFiles, password: nil, progress: {progress in
    //                    self.labelPreparing.text = "Preparing...".localized() + " \(progress * 100)%"
    //                })
                    let unzipProgress = Progress()
                    let observation = unzipProgress.observe(\.fractionCompleted) { progress, _ in
                        self.labelPreparing.text = "Preparing...".localized() + " \(progress.fractionCompleted * 100)%"
                    }
                    try fileManager.zipItem(at: file_message, to: zipFiles, progress: unzipProgress)
                    guard let archive = Archive(url: zipFiles, accessMode: .update) else  {
                        return
                    }
                    do {
                        try archive.addEntry(with: file_uc_list.lastPathComponent, relativeTo: file_uc_list.deletingLastPathComponent())
                        try archive.addEntry(with: file_form_data.lastPathComponent, relativeTo: file_form_data.deletingLastPathComponent())
                        try archive.addEntry(with: file_task_pic.lastPathComponent, relativeTo: file_task_pic.deletingLastPathComponent())
                        try archive.addEntry(with: file_task_detail.lastPathComponent, relativeTo: file_task_detail.deletingLastPathComponent())
                    } catch {
                        //print("Adding entry to ZIP archive failed with error:\(error)")
                    }
                    self.labelPreparing.text = "Uploading...".localized()
                    Network().uploadHTTP(fileUrl: zipFiles, completion: { result,progress in
                        if result {
                            DispatchQueue.main.async { [self] in
                                labelPreparing.text = "Uploading...".localized() + " \(progress)%"
                                if progress == 100 {
                                    do {
                                        let path = zipFiles.path
                                        let attrib = try FileManager.default.attributesOfItem(atPath: path)
                                        let fileSize = attrib[.size] as! Int64
                                        DispatchQueue.global().async { [self] in
                                            _ = Nexilis.write(message: CoreMessage_TMessageBank.getBackupUploaded(option: choosenOption, fileid: fileIdBackup, filesize: String(fileSize), recordSize: String(recordSize)))
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
                                        
                                        labelPreparing.text = "Successfully Backup Data".localized()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [self] in
                                            isBackupStart = false
                                            tableView.beginUpdates()
                                            tableView.reloadRows(at: [indexPath, IndexPath(row: 0, section: 0)], with: .none)
                                            tableView.reloadSections(IndexSet(integer: 2), with: .none)
                                            tableView.endUpdates()
                                        })
                                    } catch {}
                                }
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
