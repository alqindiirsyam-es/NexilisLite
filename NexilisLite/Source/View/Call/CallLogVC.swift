//
//  CallFragment.swift
//  AppBuilder
//
//  Created by Qindi on 09/04/25.
//

import Foundation
import UIKit

public class CallLogVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchController = UISearchController(searchResultsController: nil)
        
    private var calls: [CallModel] = []
    private let textCallEmpty = UILabel()
    
    public override func viewDidLoad() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellCallLog")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.backgroundColor = .clear
        tableView.automaticallyAdjustsScrollIndicatorInsets = false
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        setupTableView()
        refresh()
        NotificationCenter.default.addObserver(self, selector: #selector(onRefreshCallLog(notification:)), name: NSNotification.Name(rawValue: "refreshCallLog"), object: nil)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        navigationItem.title = "Calls".localized()
        navigationItem.hidesSearchBarWhenScrolling = true
        tabBarController?.navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.tintColor = .black
        navigationController?.navigationBar.overrideUserInterfaceStyle = .light
        self.setNeedsStatusBarAppearanceUpdate()
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black, NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)]
        let largeAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black, NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 34)]
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = attributes
        appearance.largeTitleTextAttributes = largeAttributes
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
        
//        let leftButton = UIButton(type: .system)
//        let imageLeft = UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold))
//        leftButton.setImage(imageLeft, for: .normal)
//        leftButton.tintColor = .black
//        leftButton.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
//        leftButton.layer.cornerRadius = 15
//        leftButton.clipsToBounds = true
//        leftButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
//        leftButton.addTarget(self, action: #selector(leftBarButtonTapped), for: .touchUpInside)
//        let leftBarButtonItem = UIBarButtonItem(customView: leftButton)
//        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        let rightButton = UIButton(type: .system)
        let imageRight = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold))
        rightButton.setImage(imageRight, for: .normal)
        if #unavailable(iOS 26.0) {
            rightButton.tintColor = .white
            rightButton.backgroundColor = .whatsappGreenColor
        } else {
            rightButton.tintColor = .black
        }
        rightButton.layer.cornerRadius = 15
        rightButton.clipsToBounds = true
        rightButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        rightButton.addTarget(self, action: #selector(rightBarButtonTapped), for: .touchUpInside)
        let rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        navigationItem.rightBarButtonItem = rightBarButtonItem
        
        searchController.searchResultsUpdater = self
        searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "Search".localized(), attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)])
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.delegate = self

        navigationItem.searchController = searchController
        definesPresentationContext = true
        DispatchQueue.main.async {
            self.navigationController?.navigationBar.sizeToFit()
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        if Nexilis.floatingButton.isHidden {
            Nexilis.floatingButton.isHidden = false
        }
    }
    
    private func refresh() {
        getData()
        
        if calls.count > 0 {
            if textCallEmpty.isDescendant(of: view){
                textCallEmpty.removeFromSuperview()
            }
            searchController.searchBar.isHidden = false
            tableView.reloadData()
        } else {
            searchController.searchBar.isHidden = true
            textCallEmpty.numberOfLines = 0
            let fullText = "To place audio or video call, tap ⊕ at the top and select a contact.".localized()
            let attributedString = NSMutableAttributedString(string: fullText)
            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 25), range: NSRange(location: 0, length: attributedString.length))
            if let plusRange = fullText.range(of: "⊕") {
                let nsRange = NSRange(plusRange, in: fullText)
                attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 40), range: nsRange)
            }
            textCallEmpty.attributedText = attributedString
            
            view.addSubview(textCallEmpty)
            textCallEmpty.anchor(left: view.leftAnchor, right: view.rightAnchor, paddingLeft: 20, paddingRight: 20, centerX: view.centerXAnchor, centerY: view.centerYAnchor)
        }
    }
    
    @objc func onRefreshCallLog(notification: NSNotification) {
        DispatchQueue.main.async {
            self.refresh()
        }
    }
    
    private func getData() {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin, l_pin, message_text, server_date, message_scope_id from MESSAGE where message_scope_id = '\(MessageScope.CALL)' or message_scope_id = '\(MessageScope.MISSED_CALL)' order by server_date desc") {
                var tempCall: [CallModel] = []
                while cursor.next() {
                    let fPin = cursor.string(forColumnIndex: 0) ?? ""
                    let lPin = cursor.string(forColumnIndex: 1) ?? ""
                    let text = cursor.string(forColumnIndex: 2) ?? ""
                    let time = cursor.string(forColumnIndex: 3) ?? ""
                    let scope = cursor.string(forColumnIndex: 4) ?? ""
                    let me = User.getMyPin() ?? ""
                    let pin = fPin == me ? lPin : fPin
                    let dataPin = User.getDataCanNil(pin: pin, fmdb: fmdb)
                    var statusCall = "1"
                    if scope == MessageScope.CALL && fPin == me {
                        statusCall = "2"
                    } else if scope == MessageScope.MISSED_CALL {
                        statusCall = "3"
                    }
                    
                    var timeCall = ""
                    let date = Date(milliseconds: Int64(time) ?? 0)
                    let calendar = Calendar.current
                    
                    if (calendar.isDateInToday(date)) {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm"
                        formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                        timeCall = formatter.string(from: date as Date)
                    } else {
                        let startOfNow = calendar.startOfDay(for: Date())
                        let startOfTimeStamp = calendar.startOfDay(for: date)
                        let components = calendar.dateComponents([.day], from: startOfNow, to: startOfTimeStamp)
                        let day = -(components.day!)
                        if day == 1 {
                            timeCall = "Yesterday".localized()
                        } else {
                            if day < 7 {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "EEEE"
                                let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
                                if lang == "id" {
                                    formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                                }
                                timeCall = formatter.string(from: date)
                            } else {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "M/dd/yy"
                                formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                                let stringFormat = formatter.string(from: date as Date)
                                timeCall = stringFormat
                            }
                        }
                    }
                    if dataPin != nil {
                        tempCall.append(CallModel(fPin: fPin, name: dataPin!.fullName, image: dataPin!.thumb, time: timeCall, isVideo: text.lowercased().contains("audio") ? false : true, status: statusCall))
                    }
                }
                calls = tempCall
                cursor.close()
            }
        })
    }
    
    @objc func leftBarButtonTapped() {
        print("Left bar button tapped")
    }
    
    @objc func rightBarButtonTapped() {
        APIS.openCall()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        
        if calls.count > 0 {
            let label = UILabel()
            label.text = "Recent".localized()
            label.font = .boldSystemFont(ofSize: 20)
            label.textColor = .black
            label.frame = CGRect(x: 20, y: 0, width: tableView.frame.width, height: 40)
            header.addSubview(label)
        }
        
        return header
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let sectionHeaderHeight: CGFloat = 40
        if scrollView.contentOffset.y <= sectionHeaderHeight && scrollView.contentOffset.y >= 0 {
            scrollView.contentInset.top = -scrollView.contentOffset.y
        } else if scrollView.contentOffset.y >= sectionHeaderHeight {
            scrollView.contentInset.top = -sectionHeaderHeight
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return calls.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let call = calls[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellCallLog", for: indexPath)
        cell.backgroundColor = .clear
        let textTime = UILabel()
        textTime.text = call.time
        textTime.font = .systemFont(ofSize: 14)
        textTime.textColor = .gray
        textTime.textAlignment = .right
        textTime.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textTime.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        let detailButton = UIButton(type: .detailDisclosure)
        detailButton.addTarget(self, action: #selector(detailButtonTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [textTime, detailButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let container = UIView()
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        container.frame = CGRect(x: 0, y: 0, width: 120, height: 30)
        
        cell.accessoryView = container
        cell.tintColor = .black
        
        var content = cell.defaultContentConfiguration()
        content.text = call.name
        content.textProperties.font = .systemFont(ofSize: 16)
        if call.status == "3" {
            content.textProperties.color = .red
        }
        content.secondaryAttributedText = typeCallLog(type: call.status, isVideo: call.isVideo)
        content.secondaryTextProperties.font = .systemFont(ofSize: 14)
        content.secondaryTextProperties.color = .gray
        getImage(name: call.image, placeholderImage: UIImage(systemName: "person.circle.fill"), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
            content.image = image
        })
        let constantSize = 40.0
        content.imageProperties.tintColor = .lightGray
        content.imageProperties.maximumSize = CGSize(width: constantSize, height: constantSize)
        content.imageProperties.reservedLayoutSize = CGSize(width: constantSize, height: constantSize)
        content.imageProperties.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: constantSize)
        cell.contentConfiguration = content
        
        return cell
    }
    
    @objc func detailButtonTapped() {
        print("Detail button tapped")
    }
    
    public func updateSearchResults(for searchController: UISearchController) {
    }
    
    private func typeCallLog(type: String, isVideo: Bool) -> NSMutableAttributedString {
        let imageAttachment = NSTextAttachment()
        var stringImage = ""
        if isVideo && type == "2" {
            stringImage = "arrow.up.right.video.fill"
        } else if !isVideo && type == "2" {
            stringImage = "phone.fill.arrow.up.right"
        } else if isVideo {
            stringImage = "arrow.down.left.video.fill"
        } else {
            stringImage = "phone.fill.arrow.down.left"
        }
        if let image = UIImage(systemName: stringImage)?.withRenderingMode(.alwaysTemplate) {
            let imageView = UIImageView(image: image)
            imageView.tintColor = .gray
            
            // Render the UIImageView to UIImage with tint applied
            UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, 0.0)
            imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
            let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            imageAttachment.image = tintedImage
        }

        let imageSize = CGSize(width: 18, height: 18)
        imageAttachment.bounds = CGRect(x: 0, y: -2, width: isVideo ? imageSize.width + 8 : imageSize.width, height: imageSize.height)

        let imageString = NSAttributedString(attachment: imageAttachment)
        let textString = NSAttributedString(string: type == "1" ? (" " + "Incoming".localized()) : type == "2" ? (" " + "Outgoing".localized()) : (" " + "Missed".localized()), attributes: [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.gray
        ])
        
        let finalString = NSMutableAttributedString()
        finalString.append(imageString)
        finalString.append(textString)
        
        return finalString
    }
}
