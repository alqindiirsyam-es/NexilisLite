//
//  HistoryBroadcastViewController.swift
//  QmeraLite
//
//  Created by Qindi on 19/01/22.
//

import UIKit

class HistoryBroadcastViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var isAdmin: Bool = false
    var chats: [Chat] = []
    private var historyTableView = UITableView()
    let viewCounter = UIView()
    
    override func viewWillAppear(_ animated: Bool) {
        getChats {
            DispatchQueue.main.async {
                self.historyTableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondaryColor
        
        title = "Notification Center".localized()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(sender:)))
        
        let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0), NSAttributedString.Key.foregroundColor: UIColor.white]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
        navBarAppearance.titleTextAttributes = attributes
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        let me = User.getMyPin()!
        Database.shared.database?.inTransaction({ fmdb, rollback in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select official_account from BUDDY where F_PIN = '\(me)'"), cursor.next() {
                    let official = cursor.string(forColumnIndex: 0)!
                    isAdmin = User.isOfficial(official_account: official)
                    cursor.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        if isAdmin  {
            let broadcastImage = UIImage(systemName: "plus.bubble.fill")
            let buttonBroadcast = UIBarButtonItem(image: broadcastImage,  style: .plain, target: self, action: #selector(didTapBroadcastButton(sender:)))
            navigationItem.rightBarButtonItem = buttonBroadcast
        }
        
        historyTableView.register(UITableViewCell.self, forCellReuseIdentifier: "historyBroadcastCell")
        historyTableView.dataSource = self
        historyTableView.delegate = self
        view.addSubview(historyTableView)
        historyTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            historyTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            historyTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            historyTableView.topAnchor.constraint(equalTo: view.topAnchor),
            historyTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        historyTableView.tableFooterView = UIView()
//        getChats {
//            DispatchQueue.main.async {
//                self.historyTableView.reloadData()
//            }
//        }
        NotificationCenter.default.addObserver(self, selector: #selector(onReceiveMessage(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerReceiveChat), object: nil)
    }
    
    @objc func onReceiveMessage(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        guard let dataMessage = data["message"] as? TMessage else {
            return
        }
        let isUser = User.getDataCanNil(pin: dataMessage.getBody(key: CoreMessage_TMessageKey.L_PIN)) != nil
        let chatId = dataMessage.getBody(key: CoreMessage_TMessageKey.CHAT_ID, default_value: "").isEmpty ? dataMessage.getBody(key: CoreMessage_TMessageKey.L_PIN) : dataMessage.getBody(key: CoreMessage_TMessageKey.CHAT_ID, default_value: "")
        let pin = isUser ? dataMessage.getBody(key: CoreMessage_TMessageKey.F_PIN) : chatId
        if let _ = chats.firstIndex(of: Chat(pin: pin)) {
            getChats {
                DispatchQueue.main.async {
                    self.historyTableView.reloadData()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if chats.count != 0 {
            let data: Chat
            data = chats[indexPath.row]
            let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
            editorPersonalVC.hidesBottomBarWhenPushed = true
            editorPersonalVC.unique_l_pin = data.pin
            navigationController?.show(editorPersonalVC, sender: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if chats.count == 0 {
            return 1
        }
        return chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyBroadcastCell", for: indexPath)
        historyTableView.separatorStyle = .singleLine
        cell.textLabel!.text = ""
        cell.selectionStyle = .gray
        let content = cell.contentView
        if content.subviews.count > 0 {
            content.subviews.forEach { $0.removeFromSuperview() }
        }
        if chats.count == 0 {
            historyTableView.separatorStyle = .none
            cell.textLabel!.text = "No History".localized()
            cell.textLabel?.font = UIFont.systemFont(ofSize: 10)
            cell.selectionStyle = .none
            cell.textLabel?.textAlignment = .center
        } else {
            cell.separatorInset.left = 60.0
            let data: Chat
            data = chats[indexPath.row]
            let imageView = UIImageView()
            content.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 10.0),
                imageView.topAnchor.constraint(equalTo: content.topAnchor, constant: 10.0),
                imageView.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20.0),
                imageView.widthAnchor.constraint(equalToConstant: 40.0),
                imageView.heightAnchor.constraint(equalToConstant: 40.0)
            ])
            if data.profile.isEmpty && data.pin != "-999" {
                let user = User.getDataCanNil(pin: data.pin)
                if user != nil {
                    imageView.image = UIImage(named: "Profile---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                } else {
                    imageView.image = UIImage(named: "Conversation---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                }
            } else {
                if !Utils.getIconDock().isEmpty {
                    let urlString = Utils.getUrlDock()!
                    if let cachedImage = ImageCache.shared.image(forKey: urlString) {
                        let imageData = cachedImage
                        imageView.image = imageData
                    } else {
                        DispatchQueue.global().async{
                            Utils.fetchDataWithCookiesAndUserAgent(from: URL(string: urlString)!) { data, response, error in
                                guard let data = data, error == nil else { return }
                                DispatchQueue.main.async() {
                                    if UIImage(data: data) != nil {
                                        let imageData = UIImage(data: data)!
                                        imageView.image = imageData
                                        ImageCache.shared.save(image: imageData, forKey: urlString)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    getImage(name: data.profile, placeholderImage: UIImage(named: data.pin == "-999" ? "pb_button" : "Conversation---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                        imageView.image = image
                        if !result {
                            imageView.tintColor = .mainColor
                        }
                    })
                }
            }
            let titleView = UILabel()
            content.addSubview(titleView)
            titleView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                titleView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10.0),
                titleView.topAnchor.constraint(equalTo: content.topAnchor, constant: 10.0),
                titleView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -40.0),
            ])
            titleView.text = data.name
            titleView.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            
            let messageView = UILabel()
            content.addSubview(messageView)
            messageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                messageView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10.0),
                messageView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 5.0),
                messageView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -40.0),
            ])
            messageView.textColor = .gray
            let text = Utils.previewMessageText(chat: data)
            if let attributeText = text as? NSAttributedString {
                messageView.attributedText = attributeText
            } else if let stringText = text as? String {
                messageView.text = stringText
            }
            messageView.font = UIFont.systemFont(ofSize: 12)
            messageView.numberOfLines = 2
            
            if viewCounter.isDescendant(of: content) {
                viewCounter.subviews.forEach({ $0.removeFromSuperview() })
                viewCounter.removeConstraints(viewCounter.constraints)
                viewCounter.removeFromSuperview()
            }
            
            if data.counter != "0" {
                content.addSubview(viewCounter)
                viewCounter.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    viewCounter.centerYAnchor.constraint(equalTo: content.centerYAnchor),
                    viewCounter.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
                    viewCounter.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
                    viewCounter.heightAnchor.constraint(equalToConstant: 20)
                ])
                viewCounter.backgroundColor = .systemRed
                viewCounter.layer.cornerRadius = 10
                viewCounter.clipsToBounds = true
                viewCounter.layer.borderWidth = 0.5
                viewCounter.layer.borderColor = UIColor.secondaryColor.cgColor

                let labelCounter = UILabel()
                viewCounter.addSubview(labelCounter)
                labelCounter.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    labelCounter.centerYAnchor.constraint(equalTo: viewCounter.centerYAnchor),
                    labelCounter.leadingAnchor.constraint(equalTo: viewCounter.leadingAnchor, constant: 2),
                    labelCounter.trailingAnchor.constraint(equalTo: viewCounter.trailingAnchor, constant: -2),
                ])
                labelCounter.font = UIFont.systemFont(ofSize: 11)
                if Int(data.counter)! > 99 {
                    labelCounter.text = "99+"
                } else {
                    labelCounter.text = data.counter
                }
                labelCounter.textColor = .secondaryColor
                labelCounter.textAlignment = .center
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
    
    func getChats(completion: @escaping ()->()) {
        DispatchQueue.global().async {
            self.chats.removeAll()
            self.chats.append(contentsOf: Chat.getData())
            self.chats = self.chats.filter({($0.official == "1" || $0.pin == "-999") && $0.messageScope == MessageScope.WHISPER})
            completion()
        }
    }
    
    @objc func cancel(sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapBroadcastButton(sender: AnyObject){
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "broadcastNav")
        self.navigationController?.present(controller, animated: true, completion: nil)
    }
}
