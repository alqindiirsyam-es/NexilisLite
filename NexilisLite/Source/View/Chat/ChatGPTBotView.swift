//
//  ChatGPTBotView.swift
//  NexilisLite
//
//  Created by Maronakins on 21/09/23.
//

import UIKit
import Alamofire
import NotificationBannerSwift
import nuSDKService

class ChatGPTBotView: UIViewController, UIGestureRecognizerDelegate {
    public var dataPerson : [String: String?] = [
        "f_pin" : "-997",
        "firstName" : "GPT SmartBot",
        "picture" : ""
    ]
    var dataMessages: [[String: Any?]] = []
    var dataDates: [String] = []
    var chatGPTMessages: [[String: String]] = []
    
    @IBOutlet var tableChatView: UITableView!
    @IBOutlet var viewTextField: UIView!
    @IBOutlet var buttonSendChat: UIButton!
    @IBOutlet var textFieldSend: CustomTextView!
    @IBOutlet var heightTextFieldSend: NSLayoutConstraint!
    
    @IBOutlet var constraintBottomTableViewWithTextfield: NSLayoutConstraint!
    @IBOutlet var constraintTopTextField: NSLayoutConstraint!
    @IBOutlet var constraintViewTextField: NSLayoutConstraint!
    
    
    var gettingDataMessage = true
    var listViewOnSection: [UIView] = []
    var currentIndexpath: IndexPath?
    
    public var unique_l_pin = ""
    var counter = 0
    var markerCounter: String?
    var buttonScrollToBottom = UIButton()
    let indicatorCounterBSTB = UIView()
    let labelCounter = UILabel()
    var titleText: String!
    
    var isSearching = false
    var searchBar: UISearchBar!
    
    let containerMultpileSelectSession = UIView()
    var constraintBottomContainerMultpileSelectSession = NSLayoutConstraint()
    
    var copySession = false
    var deleteSession = false
    
    var showMenuContext = false
    var touchedSubview = UIView()
    
    var titleSearchMatches: UILabel!
    var textSearch = ""
    var countMatchesSearch = 0
    var lastScrollIdxSearch = 0
    var buttonUp: UIButton!
    var buttonDown: UIButton!
    
    public var fromNotification = true
    
    var lastY: CGFloat = 0
    
    var allowTyping = true
    
    struct Payload: Encodable {
        let use_video : String
        let payload : [[String: String]]
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            SecureUserDefaults.shared.removeValue(forKey: "inEditorPersonal")
            NotificationCenter.default.removeObserver(self)
            super.viewDidDisappear(true)
            self.removeFromParent()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.overrideUserInterfaceStyle = .dark
        navigationController?.navigationBar.barStyle = .black
        if self.navigationController?.isNavigationBarHidden ?? false {
            self.navigationController?.setNavigationBarHidden(false, animated: false)
        }
        gettingDataMessage = false
        let indexPath = tableChatView.indexPathsForVisibleRows?.first
        if indexPath != nil {
            let headerRect = tableChatView.rectForHeader(inSection: indexPath!.section)
            let isPinned = headerRect.origin.y <= tableChatView.contentOffset.y
            if listViewOnSection.count != 0 && listViewOnSection.count - 1 == indexPath!.section && isPinned {
                let sect = listViewOnSection.count - 1 < currentIndexpath!.section ? listViewOnSection.count - 1 : currentIndexpath!.section
                let headerView = listViewOnSection[sect]
                headerView.isHidden = true
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.topItem?.title = "GPT SmartBot"
        
        buttonSendChat.setImage(resizeImage(image: self.traitCollection.userInterfaceStyle == .dark ? UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(.blackDarkMode) : UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal), for: .normal)
        buttonSendChat.circle()
        buttonSendChat.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        buttonSendChat.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
        textFieldSend.layer.cornerRadius = textFieldSend.maxCornerRadius()
        textFieldSend.layer.borderWidth = 1.0
        textFieldSend.text = "Send message".localized()
        textFieldSend.textColor = UIColor.lightGray
        textFieldSend.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        textFieldSend.textContainerInset = UIEdgeInsets(top: 12, left: 20, bottom: 11, right: 40)
        textFieldSend.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        textFieldSend.font = UIFont.systemFont(ofSize: 12)
        textFieldSend.delegate = self
        textFieldSend.allowsEditingTextAttributes = true
        
        navigationItem.rightBarButtonItem?.tintColor = UIColor.secondaryColor
        
        tableChatView.register(UITableViewCell.self, forCellReuseIdentifier: "cellEditorPersonal")
        
        loadData()
        setRightButtonItem()
        
        addGreeting()
        
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(onReceiveMessage(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerReceiveChat), object: nil)
        center.addObserver(self, selector: #selector(onStatusChat(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerStatusChat), object: nil)
        center.addObserver(self, selector: #selector(onTyping(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerTypingChat), object: nil)
        
        
    }
    
    private func addGreeting() {
        guard let me = User.getMyPin() else {
            return
        }
        var user_id:String? = ""
        let message_id = me + CoreMessage_TMessageUtil.getTID()
        let server_date = String(Date().currentTimeMillis())
        
        var gptRow : [String: String] = [:]
        gptRow["role"] = "assistant"
        gptRow["content"] = Utils.getChatbotGreetings()
        chatGPTMessages.append(gptRow)
        
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select user_id from BUDDY where f_pin = '\(me)'"), cursor.next() {
                    user_id = cursor.string(forColumnIndex: 0)
                    cursor.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                    "message_id" : message_id ,
                    "f_pin" : "-997",
                    "f_display_name" : "GPT SmartBot",
                    "l_pin" : me,
                    "l_user_id" : String(user_id!),
                    "message_scope_id" : "31",
                    "server_date" : server_date,
                    "status" : "3",
                    "message_text" : gptRow["content"],
                    "audio_id" : "",
                    "video_id" : "",
                    "image_id" : "",
                    "file_id" : "",
                    "thumb_id" : "",
                    "opposite_pin" : "",
                    "format" : "",
                    "blog_id" : "",
                    "read_receipts" : "0",
                    "chat_id" : "",
                    "account_type" : "1",
                    "credential" :"",
                    "reff_id" : "",
                    "message_large_text" : "",
                    "attachment_flag" : "0",
                    "local_timestamp" : String(Date().currentTimeMillis())
                ], replace: true)
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        let pin = "-997"
        var counter : Int? = nil
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select counter from MESSAGE_SUMMARY where l_pin = '\(pin)'"), cursor.next() {
                    counter = Int(cursor.int(forColumnIndex: 0))
                    counter! += 0
                    cursor.close()
                    //print("select db message summary")
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        if counter == nil {
            counter = 0
            //print("set counter message summary")
        }
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                    "l_pin" : pin,
                    "message_id" : message_id,
                    "counter" : counter!
                ], replace: true)
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        var row: [String: Any?] = [:]
        row["message_id"] = message_id
        row["f_pin"] = "-997"
        row["l_pin"] = me
        row["message_scope_id"] = "31"
        row["server_date"] = server_date
        row["status"] = "3"
        row["message_text"] = gptRow["content"]
        row["audio_id"] = ""
        row["video_id"] = ""
        row["image_id"] = ""
        row["thumb_id"] = ""
        row["read_receipts"] = "0"
        row["credential"] = ""
        row["file_id"] = ""
        row["reff_id"] = ""
        row["progress"] = 100.0
        row["attachment_flag"] = "0"
        row["lock"] = ""
        row["is_stared"] = "0"
        row["isSelected"] = false
        if !self.dataDates.contains("Today".localized()) {
            self.dataDates.append("Today".localized())
            self.tableChatView.insertSections(IndexSet(integer: self.dataDates.count - 1), with: .none)
        }
        row["chat_date"] = "Today".localized()
        row["blog_id"] = "0"
        self.dataMessages.append(row)
        self.tableChatView.insertRows(at: [IndexPath(row: self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[self.dataDates.count - 1]}).count - 1, section: self.dataDates.count - 1)], with: .none)
        self.tableChatView.scrollToBottom()
    }
    
    @objc func sendTapped() {
        sendChat(message_text: textFieldSend.text!, viewController: self)
    }
    
    @objc func didTapExit() {
        self.dismiss(animated: true)
//        if complaintId.isEmpty || fromVCAC {
//            for timer in self.timerCredential.values {
//                timer.invalidate()
//            }
//            self.timeoutCC.invalidate()
//            NotificationCenter.default.removeObserver(self)
//            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshView"), object: nil, userInfo: nil)
//            self.dismiss(animated: true, completion: nil)
//        } else if !complaintId.isEmpty {
//            let alert = LibAlertController(title: "Interaction with Call Center is in progress".localized(), message: "Are you sure you want to end the Call Center?".localized(), preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: nil))
//            alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: {(_) in
//                self.endCallCenter()
//            }))
//            self.present(alert, animated: true, completion: nil)
//        }
    }
    
    private func sendChat(message_scope_id:String =  "31", status:String =  "4", message_text:String =  "", credential:String = "0", attachment_flag: String = "0", ex_blog_id: String = "", message_large_text: String = "", ex_format: String = "", image_id: String = "", audio_id: String = "", video_id: String = "", file_id: String = "", thumb_id: String = "", reff_id: String = "", read_receipts: String = "4", chat_id: String = "", is_call_center: String = "0", call_center_id: String = "", viewController: UIViewController) {
        if viewController is ChatGPTBotView {
            if ((textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) == "Send message".localized() && textFieldSend.textColor == UIColor.lightGray && attachment_flag != "11") || textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ) {
                dismissKeyboard()
                viewController.showToast(message: "Write Messages".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                if (textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "Send message".localized()) {
                    textFieldSend.text = ""
                }
                if (self.heightTextFieldSend.constant != 40) {
                    self.heightTextFieldSend.constant = 40
                }
                return
            }
        }
        var l_pin = dataPerson["f_pin"]!!
        var message_scope_id = message_scope_id
        var chat_id = chat_id
        let message_text = message_text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let idMe = User.getMyPin() as String?
        var opposite_pin = idMe ?? ""
        sendTyping(l_pin: l_pin, isTyping: true)
        let message = CoreMessage_TMessageBank.sendMessage(l_pin: l_pin, message_scope_id: message_scope_id, status: status, message_text: message_text, credential: credential, attachment_flag: attachment_flag, ex_blog_id: ex_blog_id, message_large_text: message_large_text, ex_format: ex_format, image_id: image_id, audio_id: audio_id, video_id: video_id, file_id: file_id, thumb_id: thumb_id, reff_id: reff_id, read_receipts: read_receipts, chat_id: chat_id, is_call_center: is_call_center, call_center_id: call_center_id, opposite_pin: opposite_pin)
        Nexilis.saveMessage(message: message)
        let messageId = String(message.mBodies[CoreMessage_TMessageKey.MESSAGE_ID]!)
        var row: [String: Any?] = [:]
        row["message_id"] = messageId
        row["f_pin"] = idMe
        row["l_pin"] = dataPerson["f_pin"]!!
        row["message_scope_id"] = message_scope_id
        row["server_date"] = "\(Date().currentTimeMillis())"
        row["status"] = status
        row["message_text"] = message_text
        row["audio_id"] = audio_id
        row["video_id"] = video_id
        row["image_id"] = image_id
        row["thumb_id"] = thumb_id
        row["read_receipts"] = read_receipts
        row["credential"] = credential
        row["chat_id"] = chat_id
        row["file_id"] = file_id
        row["attachment_flag"] = attachment_flag
        row["reff_id"] = reff_id
        row["progress"] = 0.0
        row["lock"] = "0"
        row["is_stared"] = "0"
        row["isSelected"] = false
        if !dataDates.contains("Today".localized()) {
            dataDates.append("Today".localized())
            tableChatView.insertSections(IndexSet(integer: dataDates.count - 1), with: .none)
        }
        row["chat_date"] = "Today".localized()
        dataMessages.append(row)
        var gptRow : [String: String] = [:]
        gptRow["role"] = row["f_pin"] as! String == "-997" ? "assistant" : "user"
        gptRow["content"] = row["message_text"] as? String
        chatGPTMessages.append(gptRow)
        request(mesage: row["message_text"] as! String)
        tableChatView.insertRows(at: [IndexPath(row: dataMessages.filter({ $0["chat_date"] as! String == dataDates[dataDates.count - 1]}).count - 1, section: dataDates.count - 1)], with: .none)
        if textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "Send message".localized() && textFieldSend.textColor != UIColor.lightGray && constraintViewTextField.constant == 0 {
            textFieldSend.text = "Send message".localized()
            textFieldSend.textColor = UIColor.lightGray
        } else if constraintViewTextField.constant != 0 {
            textFieldSend.text = ""
            heightTextFieldSend.constant = 40
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.tableChatView.scrollToBottom()
            if self.markerCounter != nil {
                let lastMarkerCounter = self.markerCounter
                self.markerCounter = nil
                self.tableChatView.beginUpdates()
                let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == lastMarkerCounter })
                if indexMessage != nil {
                    let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"] as! String)
                    let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[indexMessage!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                    if row != nil && section != nil  {
                        self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                    }
                }
                self.tableChatView.endUpdates()
            }
        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            self.timerFakeProgress = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//                self.updateProgress(row as [AnyHashable : Any])
//                if self.fakeProgMultip == self.maxFakeProgMultip {
//                    self.timerFakeProgress?.invalidate()
//                    self.fakeProgMultip = 0
//                }
//            }
//        }
    }
    
    private func request(mesage: String) {
        DispatchQueue.global().async {
            do {
                if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.requestGPTBot(message: mesage)) {
                    if response.isOk() {
                        let data = response.getBody(key: CoreMessage_TMessageKey.DATA)
                        if let json = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: []) as? [String: Any?] {
                            print("HMM \(json)")
                            DispatchQueue.main.async {
                                var gptRow : [String: String] = [:]
                                gptRow["role"] = json["role"] as? String
                                gptRow["content"] = json["content"] as? String
                                self.chatGPTMessages.append(gptRow)
                                guard let me = User.getMyPin() else {
                                    return
                                }
                                
                                var user_id:String? = ""
                                let message_id = me + CoreMessage_TMessageUtil.getTID()
                                let server_date = String(Date().currentTimeMillis())
                                
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select user_id from BUDDY where f_pin = '\(me)'"), cursor.next() {
                                            user_id = cursor.string(forColumnIndex: 0)
                                            cursor.close()
                                        }
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                            "message_id" : message_id ,
                                            "f_pin" : "-997",
                                            "f_display_name" : "GPT SmartBot",
                                            "l_pin" : me,
                                            "l_user_id" : String(user_id!),
                                            "message_scope_id" : "31",
                                            "server_date" : server_date,
                                            "status" : "3",
                                            "message_text" : gptRow["content"],
                                            "audio_id" : "",
                                            "video_id" : "",
                                            "image_id" : "",
                                            "file_id" : "",
                                            "thumb_id" : "",
                                            "opposite_pin" : "",
                                            "format" : "",
                                            "blog_id" : "",
                                            "read_receipts" : "0",
                                            "chat_id" : "",
                                            "account_type" : "1",
                                            "credential" :"",
                                            "reff_id" : "",
                                            "message_large_text" : "",
                                            "attachment_flag" : "0",
                                            "local_timestamp" : String(Date().currentTimeMillis())
                                        ], replace: true)
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                                let pin = "-997"
                                var counter : Int? = nil
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select counter from MESSAGE_SUMMARY where l_pin = '\(pin)'"), cursor.next() {
                                            counter = Int(cursor.int(forColumnIndex: 0))
                                            counter! += 1
                                            cursor.close()
                                            //print("select db message summary")
                                        }
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                                if counter == nil {
                                    counter = 1
                                    //print("set counter message summary")
                                }
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                                            "l_pin" : pin,
                                            "message_id" : message_id,
                                            "counter" : counter!
                                        ], replace: true)
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                                //print("insert db message summary \(message_id)")
                                var row: [String: Any?] = [:]
                                row["message_id"] = message_id
                                row["f_pin"] = "-997"
                                row["l_pin"] = me
                                row["message_scope_id"] = "31"
                                row["server_date"] = server_date
                                row["status"] = "3"
                                row["message_text"] = gptRow["content"]
                                row["audio_id"] = ""
                                row["video_id"] = ""
                                row["image_id"] = ""
                                row["thumb_id"] = ""
                                row["read_receipts"] = "0"
                                row["credential"] = ""
                                row["file_id"] = ""
                                row["reff_id"] = ""
                                row["progress"] = 100.0
                                row["attachment_flag"] = "0"
                                row["lock"] = ""
                                row["is_stared"] = "0"
                                row["isSelected"] = false
                                if !self.dataDates.contains("Today".localized()) {
                                    self.dataDates.append("Today".localized())
                                    self.tableChatView.insertSections(IndexSet(integer: self.dataDates.count - 1), with: .none)
                                }
                                row["chat_date"] = "Today".localized()
                                row["blog_id"] = "0"
                                self.counter += 1
                                self.dataMessages.append(row)
                                self.tableChatView.insertRows(at: [IndexPath(row: self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[self.dataDates.count - 1]}).count - 1, section: self.dataDates.count - 1)], with: .none)
                                if self.currentIndexpath?.row == (self.dataMessages.count - 2) {
                                    if (self.viewIfLoaded?.window != nil) {
                                        self.sendReadMessageStatus(chat_id: "", f_pin: row["f_pin"] as! String, message_scope_id: row["message_scope_id"] as! String, message_id: message_id)
                                    }
                                    self.tableChatView.scrollToBottom()
                                    if ( self.currentIndexpath!.section <= self.dataDates.count - 1 && self.currentIndexpath!.row <= self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[self.dataDates.count - 1]}).count - 1)  {
                                        self.counter = 0
                                        self.updateCounter(counter: self.counter)
                                    }
                                    let lastMarkerCounter = self.markerCounter
                                    if self.markerCounter != nil {
                                        self.markerCounter = nil
                                    }
                                    self.tableChatView.beginUpdates()
                                    let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == lastMarkerCounter })
                                    if indexMessage != nil {
                                        let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"] as! String)
                                        let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[indexMessage!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                                        if row != nil && section != nil  {
                                            self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                        }
                                    }
                                    self.tableChatView.endUpdates()
                                }
                                else if self.currentIndexpath == nil {
                                    self.counter = 0
                                    self.updateCounter(counter: self.counter)
                                    if (self.viewIfLoaded?.window != nil) {
                                        self.sendReadMessageStatus(chat_id: "", f_pin: row["f_pin"] as! String, message_scope_id: row["message_scope_id"] as! String, message_id: message_id)
                                    }
                                }
                                else if self.counter != 0 {
                                    if !self.indicatorCounterBSTB.isDescendant(of: self.view) && self.buttonScrollToBottom.isDescendant(of: self.view) {
                                        self.markerCounter = row["message_id"] as? String
                                        self.addCounterAtButttonScrollToBottom()
                                        self.tableChatView.beginUpdates()
                                        let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.markerCounter })
                                        if indexMessage != nil {
                                            let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"] as! String)
                                            let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[indexMessage!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                                            if row != nil && section != nil  {
                                                self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                            }
                                        }
                                        self.tableChatView.endUpdates()
                                    } else if self.indicatorCounterBSTB.isDescendant(of: self.view) {
                                        self.labelCounter.text = "\(self.counter)"
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                print("Error encoding data: \(error.localizedDescription)")
            }
        }
    }
    
    func loadData(){
        SecureUserDefaults.shared.set(dataPerson["f_pin"]!, forKey: "inEditorPersonal")
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [dataPerson["f_pin"]!!])
        
        if self.fromNotification {
            let imageButton = UIImageView(frame: CGRect(x: -16, y: 0, width: 20, height: 44))
            imageButton.image = UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default))?.withTintColor(.white)
            imageButton.contentMode = .left
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapExit))
            imageButton.isUserInteractionEnabled = true
            imageButton.addGestureRecognizer(tapGestureRecognizer)
            let leftItem = UIBarButtonItem(customView: imageButton)
            self.navigationItem.leftBarButtonItem = leftItem
        }
        
        changeAppBar()
        getData()
        
        tableChatView.alpha = 0
        tableChatView.delegate = self
        tableChatView.dataSource = self
        tableChatView.keyboardDismissMode = .interactive
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableChatView.addGestureRecognizer(tapGesture)
        let idMe = User.getMyPin() as String?
        for i in 0..<dataMessages.count {
            if dataMessages[i]["f_pin"] as? String != idMe {
                sendReadMessageStatus(chat_id: "", f_pin: dataPerson["f_pin"]!!, message_scope_id: "3", message_id: dataMessages[i]["message_id"] as! String)
            }
        }
        tableChatView.scrollToBottom(isAnimated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            if self.tableChatView.alpha != 1.0 {
                UIView.animate(withDuration: 0.5, animations: {
                    self.tableChatView.alpha = 1.0
                })
            }
        })
    }
    
    private func changeAppBar() {
        let viewAppBar = UIView()
        viewAppBar.frame.size = CGSize(width: self.view.frame.size.width, height: 44)
        
        if !isSearching {
            let imageProfile = UIImageView(frame: CGRect(x: 0, y: 7, width: 30, height: 30))
            imageProfile.circle()
            imageProfile.clipsToBounds = true
            var count = 0
            viewAppBar.addSubview(imageProfile)
            imageProfile.image = UIImage(named: "pb_gpt_bot", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
            imageProfile.contentMode = .scaleAspectFit
            let titleNavigation = UILabel(frame: CGRect(x: 35, y: 0, width: viewAppBar.frame.size.width - 250, height: 44))
            viewAppBar.addSubview(titleNavigation)
            titleNavigation.set(image: UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  GPT SmartBot", size: 15, y: -4)
            titleNavigation.textColor = .white
            titleNavigation.font = UIFont.systemFont(ofSize: 12).bold
            
            navigationItem.titleView = viewAppBar
            titleText = titleNavigation.text
        } else {
            searchBar = UISearchBar()
            searchBar.autocapitalizationType = .none
            searchBar.delegate = self
            searchBar.searchTextField.tintColor = .mainColor
            searchBar.searchTextField.textColor = .mainColor
//            searchBar.updateHeight(height: 36, radius: 18)
            searchBar.showsCancelButton = false
//            searchBar.setMagnifyingGlassColorTo(color: .white)
            searchBar.setImage(UIImage(), for: .search, state: .normal)
            searchBar.setPositionAdjustment(UIOffset(horizontal: 10, vertical: 0), for: .search)
            searchBar.setCustomBackgroundImage(image: UIImage(named: self.traitCollection.userInterfaceStyle == .dark ? "nx_search_bar_dark" : "nx_search_bar", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
            navigationItem.titleView = searchBar
            self.definesPresentationContext = true
        }
        
        if copySession || deleteSession || isSearching {
            navigationItem.hidesBackButton = true
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        } else {
            navigationItem.hidesBackButton = false
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
    
    private func getData() {
        var query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared, blog_id, credential FROM MESSAGE where (f_pin='\(dataPerson["f_pin"]!!)' or l_pin='\(dataPerson["f_pin"]!!)') AND message_scope_id = '31' order by server_date asc"
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    while cursorData.next() {
                        var row: [String: Any?] = [:]
                        row["message_id"] = cursorData.string(forColumnIndex: 0)
                        row["f_pin"] = cursorData.string(forColumnIndex: 1)
                        row["l_pin"] = cursorData.string(forColumnIndex: 2)
                        row["message_scope_id"] = cursorData.string(forColumnIndex: 3)
                        row["server_date"] = cursorData.string(forColumnIndex: 4)
                        row["status"] = cursorData.string(forColumnIndex: 5)
                        row["message_text"] = cursorData.string(forColumnIndex: 6)
                        row["audio_id"] = cursorData.string(forColumnIndex: 7)
                        row["video_id"] = cursorData.string(forColumnIndex: 8)
                        row["image_id"] = cursorData.string(forColumnIndex: 9)
                        row["thumb_id"] = cursorData.string(forColumnIndex: 10)
                        row["read_receipts"] = cursorData.string(forColumnIndex: 11)
                        row["chat_id"] = cursorData.string(forColumnIndex: 12)
                        row["file_id"] = cursorData.string(forColumnIndex: 13)
                        row["attachment_flag"] = cursorData.string(forColumnIndex: 14)
                        row["reff_id"] = cursorData.string(forColumnIndex: 15)
                        row["lock"] = cursorData.string(forColumnIndex: 16)
                        row["is_stared"] = cursorData.string(forColumnIndex: 17)
                        row["blog_id"] = cursorData.string(forColumnIndex: 18)
                        row["credential"] = cursorData.string(forColumnIndex: 19)
                        if let cursorStatus = Database.shared.getRecords(fmdb: fmdb, query: "SELECT status FROM MESSAGE_STATUS WHERE message_id='\(row["message_id"] as! String)'") {
                            while cursorStatus.next() {
                                row["status"] = cursorStatus.string(forColumnIndex: 0)
                            }
                            cursorStatus.close()
                        }
                        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                        if let dirPath = paths.first {
                            let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["video_id"] as! String)
                            let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["file_id"] as! String)
                            do {
                                if ((row["video_id"] as! String) != "") {
                                    if FileManager.default.fileExists(atPath: videoURL.path) || FileEncryption.shared.isSecureExists(filename: row["video_id"] as! String){
                                        row["progress"] = 100.0
                                    } else {
                                        row["progress"] = 0.0
                                    }
                                } else {
                                    if FileManager.default.fileExists(atPath: fileURL.path) || FileEncryption.shared.isSecureExists(filename: row["file_id"] as! String){
                                        row["progress"] = 100.0
                                    } else {
                                        row["progress"] = 0.0
                                    }
                                }
                            }
                        }
                        row["chat_date"] = chatDate(stringDate: row["server_date"] as! String)
                        row["isSelected"] = false
                        dataMessages.append(row)
                        var gptRow : [String: String] = [:]
                        gptRow["role"] = row["f_pin"] as! String == "-997" ? "assistant" : "user"
                        gptRow["content"] = row["message_text"] as! String
                        chatGPTMessages.append(gptRow)
                    }
                    cursorData.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    private func setRightButtonItem() {
        navigationItem.rightBarButtonItems = nil
        let actionDelete = UIAction(title: "Delete Conversation".localized(), handler: {(_) in
            let alert = LibAlertController(title: "", message: "Are you sure to delete all message in this conversation?".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete".localized(), style: .destructive, handler: {(_) in
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "f_pin='\(self.dataPerson["f_pin"]!!)' or l_pin='\(self.dataPerson["f_pin"]!!)'")
                        _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "l_pin='\(self.dataPerson["f_pin"]!!)'")
                        let l_pin = self.dataPerson["f_pin"]!!
                        SecureUserDefaults.shared.removeValue(forKey: "saved_\(l_pin)")
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                        self.navigationController?.popViewController(animated: true)
                    } catch {
                        rollback.pointee = true
                        print("Access database error: \(error.localizedDescription)")
                    }
                })
            }))
            self.present(alert, animated: true, completion: nil)
        })
        let actionSearch = UIAction(title: "Search".localized(), handler: {(_) in
            self.isSearching = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
                cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
                if self.dataPerson["f_pin"] != "-999" {
                    self.navigationItem.rightBarButtonItems = nil
                    // TODO: sus
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                self.addMultipleSelectSession()
            }
        })
        var menu = UIMenu(title: "", children: [
            actionSearch,
            actionDelete
        ])
        
        let moreIcon = UIBarButtonItem(image: UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), menu: menu)
        navigationItem.rightBarButtonItem = moreIcon
    }
    
    @objc func dismissKeyboard() {
        if isSearching {
            searchBar.resignFirstResponder()
        } else {
            textFieldSend.resignFirstResponder() // dismiss keyoard
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.viewIfLoaded?.window != nil {
            let info:NSDictionary = notification.userInfo! as NSDictionary
            let duration: CGFloat = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber as! CGFloat
            
            self.constraintViewTextField.constant = 0
            self.constraintBottomContainerMultpileSelectSession.constant = 0
            UIView.animate(withDuration: TimeInterval(duration), animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if self.viewIfLoaded?.window != nil {
            let info:NSDictionary = notification.userInfo! as NSDictionary
            let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            
            let keyboardHeight: CGFloat = keyboardSize.height
            
            let duration: CGFloat = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber as! CGFloat
            
            if self.constraintViewTextField.constant != -keyboardHeight {
                self.constraintViewTextField.constant = -keyboardHeight
                if isSearching {
                    self.constraintViewTextField.constant = self.constraintViewTextField.constant - 60
                    self.constraintBottomContainerMultpileSelectSession.constant = -keyboardHeight
                }
                UIView.animate(withDuration: TimeInterval(duration), animations: {
                    self.view.layoutIfNeeded()
                })
                if isSearching {
                    self.tableChatView.scrollToBottom()
                } else {
                    if (self.currentIndexpath != nil) {
                        self.tableChatView.scrollToRow(at: IndexPath(row: self.currentIndexpath!.row, section: self.currentIndexpath!.section), at: .none, animated: false)
                    } else {
                        self.tableChatView.scrollToBottom()
                    }
                }
            }
        }
    }
    
    @objc func onReceiveMessage(notification: NSNotification) {
        DispatchQueue.main.async { [self] in
            let data:[AnyHashable : Any] = notification.userInfo!
            if let dataMessage = data["message"] as? TMessage {
                let chatData = dataMessage.mBodies
                if (chatData[CoreMessage_TMessageKey.F_PIN] == self.dataPerson["f_pin"]!! && (chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID] == "3")) {
                    if chatData[CoreMessage_TMessageKey.F_PIN] == nil {
                        return
                    }
                    var row: [String: Any?] = [:]
                    row["message_id"] = chatData[CoreMessage_TMessageKey.MESSAGE_ID]
                    row["f_pin"] = chatData[CoreMessage_TMessageKey.F_PIN]
                    row["l_pin"] = chatData[CoreMessage_TMessageKey.L_PIN]
                    row["message_scope_id"] = chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]
                    row["server_date"] = chatData[CoreMessage_TMessageKey.SERVER_DATE]
                    row["status"] = chatData[CoreMessage_TMessageKey.STATUS]
                    row["message_text"] = chatData[CoreMessage_TMessageKey.MESSAGE_TEXT]
                    if (chatData.keys.contains(CoreMessage_TMessageKey.AUDIO_ID)) {
                        row["audio_id"] = chatData[CoreMessage_TMessageKey.AUDIO_ID]
                    } else {
                        row["audio_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.VIDEO_ID)) {
                        row["video_id"] = chatData[CoreMessage_TMessageKey.VIDEO_ID]
                    } else {
                        row["video_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.IMAGE_ID)) {
                        row["image_id"] = chatData[CoreMessage_TMessageKey.IMAGE_ID]
                    } else {
                        row["image_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.THUMB_ID)) {
                        row["thumb_id"] = chatData[CoreMessage_TMessageKey.THUMB_ID]
                    } else {
                        row["thumb_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.READ_RECEIPTS)) {
                        row["read_receipts"] = chatData[CoreMessage_TMessageKey.READ_RECEIPTS]
                    } else {
                        row["read_receipts"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.CREDENTIAL)) {
                        row["credential"] = chatData[CoreMessage_TMessageKey.CREDENTIAL]
                    } else {
                        row["credential"] = ""
                    }
                    row["chat_id"] = ""
                    if (chatData.keys.contains(CoreMessage_TMessageKey.FILE_ID)) {
                        row["file_id"] = chatData[CoreMessage_TMessageKey.FILE_ID]
                    } else {
                        row["file_id"] = ""
                    }
                    row["progress"] = 0.0
                    row["attachment_flag"] = chatData[CoreMessage_TMessageKey.ATTACHMENT_FLAG]
                    row["reff_id"] = chatData[CoreMessage_TMessageKey.REF_ID] ?? ""
                    row["lock"] = ""
                    row["is_stared"] = "0"
                    row["isSelected"] = false
                    if !self.dataDates.contains("Today".localized()) {
                        self.dataDates.append("Today".localized())
                        self.tableChatView.insertSections(IndexSet(integer: self.dataDates.count - 1), with: .none)
                    }
                    row["chat_date"] = "Today".localized()
                    row["blog_id"] = chatData[CoreMessage_TMessageKey.BLOG_ID]
                    self.counter += 1
                    self.dataMessages.append(row)
                    self.tableChatView.insertRows(at: [IndexPath(row: self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[self.dataDates.count - 1]}).count - 1, section: self.dataDates.count - 1)], with: .none)
                    if chatData[CoreMessage_TMessageKey.FORMAT] == "1" {
                        self.sendReadMessageStatus(chat_id: "", f_pin: chatData[CoreMessage_TMessageKey.F_PIN]!, message_scope_id: chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]!, message_id: chatData[CoreMessage_TMessageKey.MESSAGE_ID]!)
                        self.tableChatView.scrollToBottom()
                    } else if self.currentIndexpath?.row == (self.dataMessages.count - 2) {
                        if (self.viewIfLoaded?.window != nil) {
                            self.sendReadMessageStatus(chat_id: "", f_pin: chatData[CoreMessage_TMessageKey.F_PIN]!, message_scope_id: chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]!, message_id: chatData[CoreMessage_TMessageKey.MESSAGE_ID]!)
                        }
                        self.tableChatView.scrollToBottom()
                        if ( self.currentIndexpath!.section <= self.dataDates.count - 1 && self.currentIndexpath!.row <= self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[self.dataDates.count - 1]}).count - 1)  {
                            self.counter = 0
                            self.updateCounter(counter: self.counter)
                        }
                        let lastMarkerCounter = markerCounter
                        if self.markerCounter != nil {
                            self.markerCounter = nil
                        }
                        self.tableChatView.beginUpdates()
                        let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == lastMarkerCounter })
                        if indexMessage != nil {
                            let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"] as! String)
                            let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[indexMessage!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                            if row != nil && section != nil  {
                                self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                            }
                        }
                        self.tableChatView.endUpdates()
                    }
                    else if self.currentIndexpath == nil {
                        self.counter = 0
                        self.updateCounter(counter: self.counter)
                        if (self.viewIfLoaded?.window != nil) {
                            self.sendReadMessageStatus(chat_id: "", f_pin: chatData[CoreMessage_TMessageKey.F_PIN]!, message_scope_id: chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]!, message_id: chatData[CoreMessage_TMessageKey.MESSAGE_ID]!)
                        }
                    }
                    else if self.counter != 0 {
                        if !self.indicatorCounterBSTB.isDescendant(of: self.view) && self.buttonScrollToBottom.isDescendant(of: self.view) {
                            self.markerCounter = row["message_id"] as? String
                            self.addCounterAtButttonScrollToBottom()
                            self.tableChatView.beginUpdates()
                            let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.markerCounter })
                            if indexMessage != nil {
                                let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"] as! String)
                                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[indexMessage!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                                if row != nil && section != nil  {
                                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                }
                            }
                            self.tableChatView.endUpdates()
                        } else if self.indicatorCounterBSTB.isDescendant(of: self.view) {
                            self.labelCounter.text = "\(self.counter)"
                        }
                    }
                }
            }
        }
    }
    
    @objc func onStatusChat(notification: NSNotification) {
        DispatchQueue.main.async {
            let data:[AnyHashable : Any] = notification.userInfo!
            if let dataMessage = data["message"] as? TMessage {
                let chatData = dataMessage.mBodies
                let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
                let requester = onGoingCC.components(separatedBy: ",")[0]
                let idMe = User.getMyPin()!
                if chatData[CoreMessage_TMessageKey.F_PIN] == self.dataPerson["f_pin"]!! || chatData[CoreMessage_TMessageKey.L_PIN] == self.dataPerson["f_pin"]!! || requester == idMe {
                    if (chatData.keys.contains(CoreMessage_TMessageKey.MESSAGE_ID) && !(chatData[CoreMessage_TMessageKey.MESSAGE_ID]!).contains("-2,")) {
                        var idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == chatData[CoreMessage_TMessageKey.MESSAGE_ID]! })
                        if (idx != nil) {
                            if (chatData[CoreMessage_TMessageKey.DELETE_MESSAGE_FLAG] == "1") {
                                self.dataMessages[idx!]["lock"] = "1"
                                self.dataMessages[idx!]["reff_id"] = ""
                                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                                if row != nil && section != nil  {
                                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                }
                            } else {
                                self.dataMessages[idx!]["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
                                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                                if row != nil && section != nil  {
                                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                }
                            }
                        }
                    }
                    else if (chatData.keys.contains("message_id")) {
                        var idx = self.dataMessages.firstIndex(where: { "'\(String(describing: $0["message_id"] as? String))'" == chatData["message_id"]! })
                        if (idx != nil) {
                            if (chatData[CoreMessage_TMessageKey.DELETE_MESSAGE_FLAG] == "1") {
                                self.dataMessages[idx!]["lock"] = "1"
                                self.dataMessages[idx!]["reff_id"] = ""
                                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                                if row != nil && section != nil  {
                                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                }
                            } else {
                                self.dataMessages[idx!]["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
                                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                                if row != nil && section != nil  {
                                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                }
                            }
                        }
                    }
                    else {
                        let messageId = chatData[CoreMessage_TMessageKey.MESSAGE_ID]!.split(separator: ",")[1]
                        var idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String ?? "" == messageId })
                        if (idx != nil) {
                            self.dataMessages[idx!]["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
                            let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                            let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                            if row != nil && section != nil  {
                                self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func onTyping(notification: NSNotification) {
        DispatchQueue.main.async { [self] in
            let data:[AnyHashable : Any] = notification.userInfo!
            let message: TMessage = data["message"] as! TMessage
            let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
            if !onGoingCC.isEmpty {
                let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
                if message.getBody(key: CoreMessage_TMessageKey.F_PIN) != officer {
                    //print("RESET TIMER")
//                    timeoutCC.invalidate()
//                    timeoutCC = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false, block: {_ in
//                        let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
//                        imageView.tintColor = .white
//                        let banner = FloatingNotificationBanner(title: "Customer doesn't respond in 30 second, so call center session will be ended automatically.".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
//                        banner.show()
//                        self.endCallCenter()
//                    })
                }
            } else {
                
            }
        }
    }
    
    private func sendReadMessageStatus(chat_id: String, f_pin: String, message_scope_id: String, message_id: String) {
        let message = CoreMessage_TMessageBank.getUpdateRead(p_chat_id: chat_id, p_f_pin: f_pin, p_scope_id: message_scope_id, qty: 1)
        let fPin = message.getBody(key: CoreMessage_TMessageKey.F_PIN)
        let scope = message.getBody(key: CoreMessage_TMessageKey.SCOPE_ID)
        message.mBodies[CoreMessage_TMessageKey.SERVER_DATE] = String(Date().currentTimeMillis())
        if (fPin.elementsEqual("-999") || scope.elementsEqual("16") || scope.elementsEqual("15")){
            return
        }
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                        "status" : "4"
                    ], _where: "message_id = '\(message_id)'")
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
            message.mStatus = CoreMessage_TMessageUtil.getTID()
            message.mBodies[CoreMessage_TMessageKey.L_PIN] = f_pin
            message.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = "-2,\(message_id)"
            _ = Nexilis.write(message: message)
        }
        if let index = dataMessages.firstIndex(where: {$0["message_id"] as? String == message_id}) {
            dataMessages[index]["status"] = "4"
        }
    }
    
    func chatDate(stringDate: String) -> String {
        let date = Date(milliseconds: Int64(stringDate)!)
        let calendar = Calendar.current
        if (calendar.isDateInToday(date)) {
            if !dataDates.contains("Today".localized()){
                dataDates.append("Today".localized())
            }
            return "Today".localized()
        } else {
            let startOfNow = calendar.startOfDay(for: Date())
            let startOfTimeStamp = calendar.startOfDay(for: date)
            let components = calendar.dateComponents([.day], from: startOfNow, to: startOfTimeStamp)
            let day = -(components.day!)
            if day == 1{
                if !dataDates.contains("Yesterday".localized()){
                    dataDates.append("Yesterday".localized())
                }
                return "Yesterday".localized()
            } else if day < 7 {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
                if lang == "id" {
                    formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                }
                if !dataDates.contains(formatter.string(from: date)){
                    dataDates.append(formatter.string(from: date))
                }
                return formatter.string(from: date)
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "EE, dd MMM"
                let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
                if lang == "id" {
                    formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                }
                let stringFormat = formatter.string(from: date as Date)
                if !dataDates.contains(stringFormat){
                    dataDates.append(stringFormat)
                }
                return stringFormat
            }
        }
    }
    
    private func updateCounter(counter: Int) {
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                        "counter" : "\(counter)"
                    ], _where: "l_pin = '\(self.dataPerson["f_pin"]!!)'")
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
        }
    }
    
    private func addButtonScrollToBottom() {
        self.view.addSubview(buttonScrollToBottom)
        buttonScrollToBottom.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonScrollToBottom.bottomAnchor.constraint(equalTo: buttonSendChat.topAnchor, constant: -50),
            buttonScrollToBottom.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            buttonScrollToBottom.widthAnchor.constraint(equalToConstant: 60),
            buttonScrollToBottom.heightAnchor.constraint(equalToConstant: 30.0)
        ])
        buttonScrollToBottom.backgroundColor = .greenColor
        buttonScrollToBottom.setImage(UIImage(systemName: "chevron.down.circle"), for: .normal)
        buttonScrollToBottom.imageView?.contentMode = .scaleAspectFit
        buttonScrollToBottom.imageView?.tintColor = .white
        buttonScrollToBottom.contentVerticalAlignment = .fill
        buttonScrollToBottom.contentHorizontalAlignment = .fill
        buttonScrollToBottom.imageEdgeInsets.top = 2.0
        buttonScrollToBottom.imageEdgeInsets.bottom = 2.0
        buttonScrollToBottom.layer.cornerRadius = 10.0
        buttonScrollToBottom.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        buttonScrollToBottom.clipsToBounds = true
        buttonScrollToBottom.addTarget(self, action: #selector(scrollTobottomAction), for: .touchUpInside)
    }
    
    private func addCounterAtButttonScrollToBottom() {
        self.view.addSubview(indicatorCounterBSTB)
        indicatorCounterBSTB.translatesAutoresizingMaskIntoConstraints = false
        indicatorCounterBSTB.backgroundColor = .systemRed
        indicatorCounterBSTB.layer.cornerRadius = 7.5
        indicatorCounterBSTB.clipsToBounds = true
        indicatorCounterBSTB.layer.borderWidth = 0.5
        indicatorCounterBSTB.layer.borderColor = UIColor.secondaryColor.cgColor
        NSLayoutConstraint.activate([
            indicatorCounterBSTB.bottomAnchor.constraint(equalTo: buttonScrollToBottom.topAnchor, constant: 5),
            indicatorCounterBSTB.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -50),
            indicatorCounterBSTB.widthAnchor.constraint(greaterThanOrEqualToConstant: 15),
            indicatorCounterBSTB.heightAnchor.constraint(equalToConstant: 15)
        ])
        
        indicatorCounterBSTB.addSubview(labelCounter)
        labelCounter.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelCounter.leadingAnchor.constraint(equalTo: indicatorCounterBSTB.leadingAnchor, constant: 2),
            labelCounter.trailingAnchor.constraint(equalTo: indicatorCounterBSTB.trailingAnchor, constant: -2),
            labelCounter.centerXAnchor.constraint(equalTo: indicatorCounterBSTB.centerXAnchor),
        ])
        labelCounter.font = UIFont.systemFont(ofSize: 11)
        labelCounter.text = "\(counter)"
        labelCounter.textColor = .secondaryColor
        labelCounter.textAlignment = .center
    }
    
    @objc func scrollTobottomAction() {
        tableChatView.scrollToBottom()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [self] in
            if buttonScrollToBottom.isDescendant(of: self.view) {
                buttonScrollToBottom.removeConstraints(buttonScrollToBottom.constraints)
                buttonScrollToBottom.removeFromSuperview()
                if indicatorCounterBSTB.isDescendant(of: self.view) {
                    indicatorCounterBSTB.removeConstraints(indicatorCounterBSTB.constraints)
                    indicatorCounterBSTB.removeFromSuperview()
                }
            }
        }
    }
    
    private func checkNewMessage(tableView: UITableView) {
//        let indexPathFirst = tableView.indexPathsForVisibleRows?.first
//        if indexPathFirst != nil {
//            let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPathFirst!.section] })
//            if self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPathFirst!.row]["message_id"] as? String }) == 0 && !gettingDataMessage {
//                gettingDataMessage = true
//                addDataMessage()
//            }
//        }
        currentIndexpath = tableView.indexPathsForVisibleRows?.last
        if currentIndexpath != nil {
            let dataMessages = dataMessages.filter({ $0["chat_date"] as! String == dataDates[currentIndexpath!.section] })
            if dataMessages.count == 0 || dataMessages.count - 1 < currentIndexpath!.row {
                return
            }
            if currentIndexpath!.section == dataDates.count - 1 && currentIndexpath!.row != dataMessages.count - 1 && currentIndexpath!.row != dataMessages.count - 2 && !buttonScrollToBottom.isDescendant(of: self.view) {
                addButtonScrollToBottom()
                addCounterAtButttonScrollToBottom()
            } else if currentIndexpath!.section == dataDates.count - 1 && currentIndexpath!.row == dataMessages.count - 1 {
                if buttonScrollToBottom.isDescendant(of: self.view) {
                    buttonScrollToBottom.removeConstraints(buttonScrollToBottom.constraints)
                    buttonScrollToBottom.removeFromSuperview()
                    if indicatorCounterBSTB.isDescendant(of: self.view) {
                        indicatorCounterBSTB.removeConstraints(indicatorCounterBSTB.constraints)
                        indicatorCounterBSTB.removeFromSuperview()
                    }
                }
            }
            let indexPathFirst = tableChatView.indexPathsForVisibleRows?.first
            if indexPathFirst != nil && listViewOnSection.count != 0 && listViewOnSection.count - 1 >= indexPathFirst!.section {
                let headerView = listViewOnSection[indexPathFirst!.section]
                if headerView.isHidden {
                    headerView.isHidden = false
                }
            }
            var listData = dataMessages[0...currentIndexpath!.row]
            listData = listData.filter({$0["status"] as? String != "4" && $0["status"] as? String != "8"})
            if listData.count != 0 {
                let idMe = User.getMyPin() as String?
                for i in 0...listData.count - 1 {
                    if listData[i]["f_pin"] as? String != idMe {
                        sendReadMessageStatus(chat_id: "", f_pin: dataPerson["f_pin"]!!, message_scope_id: "31", message_id: listData[i]["message_id"] as! String)
                    }
                }
            }
        }
        if counter == 0 && indicatorCounterBSTB.isDescendant(of: self.view) {
            indicatorCounterBSTB.removeConstraints(indicatorCounterBSTB.constraints)
            indicatorCounterBSTB.removeFromSuperview()
        } else if counter != 0 && currentIndexpath != nil {
            let dataFilter = dataMessages.filter({ $0["chat_date"] as! String == dataDates[currentIndexpath!.section] })
            if dataFilter.count == 0 {
                return
            }
            let idx = dataMessages.firstIndex(where: { $0["message_id"] as? String == dataFilter[currentIndexpath!.row]["message_id"] as? String})
            if idx == nil {
                return
            }
            if (dataMessages.count - counter) <= idx! {
                let countUpdate = idx! - (dataMessages.count - counter)
                counter = counter - (countUpdate + 1)
                if indicatorCounterBSTB.isDescendant(of: self.view) {
                    labelCounter.text = "\(counter)"
                }
                updateCounter(counter: counter)
            }
        }
    }
    
    private func sendTyping(l_pin: String, isTyping: Bool = false) {
        DispatchQueue.global().async {
            let tmessage = CoreMessage_TMessageBank.getUpdateTypingStatus(p_opposite: l_pin, p_scope: "3", p_status: isTyping ? "3": "4")
            _ = Nexilis.write(message: tmessage)
        }
    }

}

extension ChatGPTBotView: UIContextMenuInteractionDelegate {
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        if showMenuContext {
            showMenuContext = false
            interaction.view!.removeInteraction(interaction)
        }
    }
    
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        if textFieldSend.isFirstResponder {
            textFieldSend.resignFirstResponder()
        }
        let indexPath = self.tableChatView.indexPathForRow(at: interaction.view!.convert(location, to: self.tableChatView))
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath!.section]})
        let copy = UIAction(title: "Copy".localized(), image: UIImage(systemName: "doc.on.doc.fill"), handler: {(_) in
            if self.isSearching {
                self.cancelAction()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.copySession = true
                let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
                cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
                if self.dataPerson["f_pin"] != "-999" {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = true
                }
                self.addMultipleSelectSession()
                self.tableChatView.reloadData()
            }
        })
        let info = UIAction(title: "Info".localized(), image: UIImage(systemName: "info.circle.fill"), handler: {(_) in
            let messageInfoVC = MessageInfo()
            messageInfoVC.data = dataMessages[indexPath!.row]
            messageInfoVC.dataPerson = self.dataPerson
            self.navigationController?.pushViewController(messageInfoVC, animated: true)
        })
        let delete = UIAction(title: "Delete".localized(), image: UIImage(systemName: "trash.fill"), attributes: .destructive, handler: {(_) in
            if self.isSearching {
                self.cancelAction()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.deleteSession = true
                let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
                cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
                if self.dataPerson["f_pin"] != "-999" {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = true
                }
                self.addMultipleSelectSession()
                self.tableChatView.reloadData()
            }
        })
        
        var children: [UIMenuElement] = [copy, delete]
//        let copyOption = self.copyOption(indexPath: indexPath!)
        let idMe = User.getMyPin() as String?
//        if (dataMessages[indexPath!.row]["lock"] != nil && dataMessages[indexPath!.row]["lock"] as! String == "1") || dataMessages[indexPath!.row]["message_scope_id"] as! String == "18" || dataPerson["f_pin"] == "-999" || dataMessages[indexPath!.row]["credential"] as! String == "1" {
//            children = [delete]
//        } else {
//            if (dataMessages[indexPath!.row]["f_pin"] as! String) == idMe {
//                children.insert(info, at: children.count - 1)
//            }
//        }
        
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { _ in
            UIMenu(title: "", children: children)
        }
    }
    
    @objc func cancelAction() {
        DispatchQueue.main.async {
            if self.copySession {
                self.copySession = false
            } else if self.deleteSession {
                self.deleteSession = false
            } else if self.isSearching {
                self.countMatchesSearch = 0
                self.isSearching = false
            }
            if self.viewTextField.isHidden {
                self.viewTextField.isHidden = false
            }
            if self.constraintBottomTableViewWithTextfield.constant == -60.0 {
                self.constraintBottomTableViewWithTextfield.constant = self.constraintBottomTableViewWithTextfield.constant + 70
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    if (self.currentIndexpath != nil) {
                        self.tableChatView.scrollToRow(at: IndexPath(row: self.currentIndexpath!.row, section: self.currentIndexpath!.section), at: .none, animated: true)
                    } else {
                        self.tableChatView.scrollToBottom()
                    }
                })
            }
            let data = self.dataMessages.filter({ $0["isSelected"] as! Bool == true })
            for i in 0..<data.count {
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == data[i]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = false
                }
            }
            self.tableChatView.reloadData()
            self.setRightButtonItem()
            self.changeAppBar()
            if self.fromNotification {
                let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(self.didTapExit))
                self.navigationItem.leftBarButtonItem = backButton
            }
            self.containerMultpileSelectSession.removeFromSuperview()
            self.checkNewMessage(tableView: self.tableChatView)
        }
    }
    
    private func addMultipleSelectSession() {
        viewTextField.isHidden = true
        constraintBottomTableViewWithTextfield.constant = constraintBottomTableViewWithTextfield.constant - 70
        view.addSubview(containerMultpileSelectSession)
        containerMultpileSelectSession.translatesAutoresizingMaskIntoConstraints = false
        constraintBottomContainerMultpileSelectSession = containerMultpileSelectSession.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0)
        NSLayoutConstraint.activate([
            containerMultpileSelectSession.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            containerMultpileSelectSession.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            constraintBottomContainerMultpileSelectSession,
            containerMultpileSelectSession.heightAnchor.constraint(equalToConstant: 50)
        ])
        containerMultpileSelectSession.backgroundColor = .white
        addSubviewMultipleSession()
    }
    
    private func addSubviewMultipleSession() {
        let container = UIView()
        containerMultpileSelectSession.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: containerMultpileSelectSession.leadingAnchor),
            container.trailingAnchor.constraint(equalTo:containerMultpileSelectSession.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: containerMultpileSelectSession.bottomAnchor),
            container.heightAnchor.constraint(equalToConstant: 50)
        ])
        container.layer.shadowOpacity = 0.7
        container.layer.shadowOffset = CGSize(width: 3, height: 3)
        container.layer.shadowRadius = 3.0
        container.layer.shadowColor = UIColor.black.cgColor
        container.backgroundColor = .secondaryColor
        
        if !isSearching {
            let title = UILabel()
            container.addSubview(title)
            title.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                title.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                title.centerYAnchor.constraint(equalTo:container.centerYAnchor),
            ])
            let countSelected = dataMessages.filter({ $0["isSelected"] as! Bool == true }).count
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
            if copySession {
                button.image = UIImage(systemName: "doc.on.doc")
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
            
        } else {
            buttonUp = UIButton()
            container.addSubview(buttonUp)
            buttonUp.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                buttonUp.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
                buttonUp.centerYAnchor.constraint(equalTo:container.centerYAnchor),
                buttonUp.widthAnchor.constraint(equalToConstant: 30),
                buttonUp.heightAnchor.constraint(equalToConstant: 30),
            ])
            buttonUp.addTarget(self, action: #selector(upSearchText), for: .touchUpInside)
            
            buttonDown = UIButton()
            container.addSubview(buttonDown)
            buttonDown.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                buttonDown.leadingAnchor.constraint(equalTo: buttonUp.trailingAnchor, constant: 15),
                buttonDown.centerYAnchor.constraint(equalTo:container.centerYAnchor),
                buttonDown.widthAnchor.constraint(equalToConstant: 30),
                buttonDown.heightAnchor.constraint(equalToConstant: 30),
            ])
            buttonDown.addTarget(self, action: #selector(downSearchText), for: .touchUpInside)
            
            buttonUp.setImage(UIImage(systemName: "chevron.up"), for: .normal)
            buttonUp.tintColor = .gray
            
            buttonDown.setImage(UIImage(systemName: "chevron.down"), for: .normal)
            buttonDown.tintColor = .gray
            
            titleSearchMatches = UILabel()
            container.addSubview(titleSearchMatches)
            titleSearchMatches.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                titleSearchMatches.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                titleSearchMatches.centerYAnchor.constraint(equalTo:container.centerYAnchor),
            ])
            titleSearchMatches.textColor = .mainColor
            titleSearchMatches.font = UIFont.systemFont(ofSize: 15.0).bold
            titleSearchMatches.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                self.searchBar.becomeFirstResponder()
            })
        }
    }
    
    @objc func upSearchText() {
        scrollToFirstSearchMessage(indexScroll: lastScrollIdxSearch + 1)
    }
    
    @objc func downSearchText() {
        scrollToFirstSearchMessage(indexScroll: lastScrollIdxSearch - 1)
    }
    
    @objc func sessionAction() {
        if copySession {
            let dataMessages = self.dataMessages.filter({ $0["isSelected"] as! Bool == true })
            let countSelected = dataMessages.count
            if countSelected == 0 {
                return
            }
            var text = ""
            for i in 0..<countSelected {
                let stringDate = (dataMessages[i]["server_date"] as! String)
                let date = Date(milliseconds: Int64(stringDate)!)
                let formatterDate = DateFormatter()
                let formatterTime = DateFormatter()
                formatterDate.dateFormat = "dd/MM/yy"
                formatterDate.locale = NSLocale(localeIdentifier: "id") as Locale?
                formatterTime.dateFormat = "HH:mm"
                formatterTime.locale = NSLocale(localeIdentifier: "id") as Locale?
                let dataProfile = getDataProfile(message_id: dataMessages[i]["message_id"] as! String)
                if text.isEmpty {
                    text = "*[\(formatterDate.string(from: date as Date)) \(formatterTime.string(from: date as Date))] \(dataProfile["name"]!):*\n\(dataMessages[i]["message_text"] as! String)"
                } else {
                    text = text + "\n\n*[\(formatterDate.string(from: date as Date)) \(formatterTime.string(from: date as Date))] \(dataProfile["name"]!):*\n\(dataMessages[i]["message_text"] as! String)"
                }
            }
            text = text + "\n\n\nchat " + "Powered by Nexilis".localized()
            DispatchQueue.main.async {
                UIPasteboard.general.string = text
                self.showToast(message: "Text coppied to clipboard".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
            }
            cancelAction()
        } else if deleteSession {
            let dataMessages = self.dataMessages.filter({ $0["isSelected"] as! Bool == true })
            var countSelected = dataMessages.count
            if countSelected == 0 {
                return
            }
            let alertController = LibAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            if let action = self.actionDelete(for: "me", title: "Delete".localized() + " \(countSelected) " + "For Me".localized(), dataMessages: dataMessages) {
                alertController.addAction(action)
            }
            let idMe = User.getMyPin() as String?
            let dataFilterFpin = dataMessages.filter({ $0["l_pin"] as? String == idMe})
            let dataFilterLock = dataMessages.filter({ $0["lock"] as? String == "1" || $0["lock"] as? String == "2" })
            let statusDataRead = dataMessages.filter({ Int($0["status"] as! String)! >= 4})
            if dataFilterFpin.count == 0 && dataFilterLock.count == 0 && statusDataRead.count == 0 {
                if let action = self.actionDelete(for: "everyone", title: "Delete".localized() + " \(countSelected) " + "For Everyone".localized(), dataMessages: dataMessages) {
                    alertController.addAction(action)
                }
            }
            alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
            self.present(alertController, animated: true)
        }
    }
    
    private func getDataProfile(message_id: String) -> [String: String]{
        var data: [String: String] = [:]
        Database().database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "select f_display_name from MESSAGE where message_id = '\(message_id)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0)!
                c.close()
            } else {
                data["name"] = "Unknown".localized()
                data["image_id"] = ""
            }
        })
        return data
    }
    
    private func deleteMessage(l_pin: String, message_id: String, scope: String, type: String, chat: String) {
        let tmessage = CoreMessage_TMessageBank.deleteMessage(l_pin: l_pin, messageId: message_id, scope: scope, type: type, chat: chat)
        Nexilis.deleteQueueMessage(message: tmessage)
    }
    
    @objc func segmentedControlValueChanged(_ sender: segmentedControllerObject) {
        switch sender.selectedSegmentIndex {
        case 0:
            sender.navigation.viewControllers[0].children[1].view.isHidden = true
            break;
        case 1:
            sender.navigation.viewControllers[0].children[1].view.isHidden = false
            break;
        default:
            break;
        }
    }
    
    private func copyOption(indexPath: IndexPath) -> UIMenu {
        var ratingButtonTitles = ["Text".localized(), "Image".localized()]
        if (dataMessages[indexPath.row]["message_text"] as! String).isEmpty {
            ratingButtonTitles = ["Image".localized()]
        }
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath.section]})
        let copyActions = ratingButtonTitles
            .enumerated()
            .map { index, title in
                return UIAction(
                    title: title,
                    identifier: nil,
                    handler: {(_) in
                        if (dataMessages[indexPath.row]["message_text"] as! String).isEmpty {
                            DispatchQueue.main.async {
                                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                                if let dirPath = paths.first {
                                    let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(dataMessages[indexPath.row]["image_id"] as! String)
                                    if FileManager.default.fileExists(atPath: imageURL.path) || FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
                                        if FileManager.default.fileExists(atPath: imageURL.path) {
                                            let image    = UIImage(contentsOfFile: imageURL.path)
                                            UIPasteboard.general.image = image
                                            self.showToast(message: "Image coppied to clipboard".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                                        }
                                        else if FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
                                            do {
                                                if let imageData = try FileEncryption.shared.readSecure(filename: imageURL.lastPathComponent) {
                                                    let image = UIImage(data: imageData)
                                                    UIPasteboard.general.image = image
                                                    self.showToast(message: "Image coppied to clipboard".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                                                }
                                            } catch {
                                                
                                            }
                                        }
                                    }
                                }
                            }
                            return
                        }
                        if (index == 0) {
                            DispatchQueue.main.async {
                                UIPasteboard.general.string = dataMessages[indexPath.row]["message_text"] as? String
                                self.showToast(message: "Text coppied to clipboard".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                            }
                        } else {
                            DispatchQueue.main.async {
                                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                                if let dirPath = paths.first {
                                    let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(dataMessages[indexPath.row]["image_id"] as! String)
                                    if FileManager.default.fileExists(atPath: imageURL.path) || FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent ) {
                                        if FileManager.default.fileExists(atPath: imageURL.path) {
                                            let image    = UIImage(contentsOfFile: imageURL.path)
                                            UIPasteboard.general.image = image
                                            self.showToast(message: "Image coppied to clipboard".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                                        }
                                        else if FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
                                            do {
                                                if let imageData = try FileEncryption.shared.readSecure(filename: imageURL.lastPathComponent) {
                                                    let image = UIImage(data: imageData)
                                                    UIPasteboard.general.image = image
                                                    self.showToast(message: "Image coppied to clipboard".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                                                }
                                            } catch {
                                                
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        self.dismissKeyboard()
                    })
            }
        return UIMenu(
            title: "Copy".localized(),
            image: UIImage(systemName: "doc.on.doc.fill"),
            children: copyActions)
    }
    
    private func actionDelete(for type: String, title: String, dataMessages: [[String: Any?]]) -> UIAlertAction? {
        return UIAlertAction(title: title, style: .destructive) { [unowned self] _ in
            for i in 0..<dataMessages.count {
                if (type == "me") {
                    self.deleteMessage(l_pin: dataMessages[i]["l_pin"] as! String, message_id: dataMessages[i]["message_id"] as! String, scope: "3", type: "1", chat: "")
                    let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[i]["message_id"] as? String})
                    if idx != nil {
                        self.dataMessages.remove(at: idx!)
                        if (idx == self.dataMessages.count - 1) {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                        }
                        for i in 0..<dataDates.count {
                            if self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[i] }).count == 0 {
                                dataDates.remove(at: i)
                            }
                        }
                    }
                } else {
                    self.deleteMessage(l_pin: dataMessages[i]["l_pin"] as! String, message_id: dataMessages[i]["message_id"] as! String, scope: "3", type: "2", chat: "")
                    let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[i]["message_id"] as? String})
                    if idx != nil {
                        self.dataMessages[idx!]["lock"] = "1"
                        self.dataMessages[idx!]["attachment_flag"] = "0"
                        self.dataMessages[idx!]["reff_id"] = ""
                    }
                }
            }
            cancelAction()
        }
    }
    
    private func updateProfile() {
        let idMe = User.getMyPin() as String?
        DispatchQueue.global().async {
            let message = CoreMessage_TMessageBank.getBatchBuddiesInfos(p_f_pin: idMe!, last_update: 0)
            let _ = Nexilis.write(message: message)
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
    
}

extension ChatGPTBotView: UITableViewDelegate, UITableViewDataSource {
//    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        checkNewMessage(tableView: tableView)
//    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if self.tableChatView.alpha != 1.0 {
            UIView.animate(withDuration: 0.5, animations: {
                self.tableChatView.alpha = 1.0
            })
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        lastY = scrollView.contentOffset.y
        DispatchQueue.main.async { [self] in
            checkNewMessage(tableView: self.tableChatView)
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath.section] })
        if copySession || deleteSession {
            if (dataMessages[indexPath.row]["attachment_flag"] as! String != "0" || dataMessages[indexPath.row]["lock"] as? String == "1") && !deleteSession {
                return
            }
            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath.row]["message_id"] as? String})
            if idx != nil {
                self.dataMessages[idx!]["isSelected"] = !(self.dataMessages[idx!]["isSelected"] as! Bool)
                self.tableChatView.reloadRows(at: [indexPath], with: .none)
            }
            containerMultpileSelectSession.subviews.forEach({ $0.removeFromSuperview() })
            addSubviewMultipleSession()
            return
        }
        let message = dataMessages[indexPath.row]
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let dateView = UIView()
        containerView.addSubview(dateView)
        dateView.translatesAutoresizingMaskIntoConstraints = false
        var topAnchor = dateView.topAnchor.constraint(equalTo: containerView.topAnchor)
        topAnchor = dateView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10.0)
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
        labelDate.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        labelDate.text = dataDates[section]
        if listViewOnSection.count == 0 || listViewOnSection.count - 1 < section {
            listViewOnSection.append(containerView)
        } else {
            listViewOnSection.remove(at: section)
            listViewOnSection.insert(containerView, at: section)
        }
        return containerView
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let idMe = User.getMyPin() as String?
        let dataMessages = dataMessages.filter({$0["chat_date"] as! String == dataDates[indexPath.section]})
        let profileMessage = UIImageView()
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellEditorPersonal", for: indexPath as IndexPath)
        cell.contentView.subviews.forEach({ $0.removeFromSuperview() })
        
        let messageIdChat = (dataMessages[indexPath.row]["message_id"] as? String) ?? ""
        
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        let nameSender = UILabel()
        
        let containerMessage = UIView()
        cell.contentView.addSubview(containerMessage)
        containerMessage.translatesAutoresizingMaskIntoConstraints = false
        
        let timeMessage = UILabel()
        cell.contentView.addSubview(timeMessage)
        timeMessage.translatesAutoresizingMaskIntoConstraints = false
        if (dataMessages[indexPath.row]["read_receipts"] as? String) == "8" || ((dataMessages[indexPath.row]["credential"] as? String) == "1" && dataMessages[indexPath.row]["lock"] as? String != "2") {
            timeMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -40).isActive = true
        } else {
            timeMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -5).isActive = true
        }
        
        let statusMessage = UIImageView()
        if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
            containerMessage.leadingAnchor.constraint(greaterThanOrEqualTo: cell.contentView.leadingAnchor, constant: 60).isActive = true
            if (dataMessages[indexPath.row]["read_receipts"] as? String) == "8" || ((dataMessages[indexPath.row]["credential"] as? String) == "1" && dataMessages[indexPath.row]["lock"] as? String != "2") {
                containerMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -40).isActive = true
            } else {
                containerMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -5).isActive = true
            }
            containerMessage.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5).isActive = true
            containerMessage.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -15).isActive = true
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            if (dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"]as? String == "") {
                containerMessage.backgroundColor = .clear
            } else {
                containerMessage.backgroundColor = .blueBubbleColor
            }
            containerMessage.layer.cornerRadius = 10.0
            containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
            containerMessage.clipsToBounds = true
            
            timeMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            
            if (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String == "0") && (dataMessages[indexPath.row]["lock"] as? String != "2") {
                cell.contentView.addSubview(statusMessage)
                statusMessage.translatesAutoresizingMaskIntoConstraints = false
                statusMessage.bottomAnchor.constraint(equalTo: timeMessage.topAnchor).isActive = true
                statusMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
                statusMessage.widthAnchor.constraint(equalToConstant: 15).isActive = true
                statusMessage.heightAnchor.constraint(equalToConstant: 15).isActive = true
                if (dataMessages[indexPath.row]["status"]! as! String == "1" || dataMessages[indexPath.row]["status"]! as! String == "2" ) {
                    statusMessage.image = UIImage(named: "checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
                } else if (dataMessages[indexPath.row]["status"]! as! String == "3") {
                    statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
                } else if (dataMessages[indexPath.row]["status"]! as! String == "8") {
                    statusMessage.image = UIImage(named: "message_status_ack", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
                } else {
                    statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
                }
            }
            
        } else {
            if markerCounter != nil && dataMessages[indexPath.row]["message_id"] as? String == markerCounter {
                containerMessage.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 35).isActive = true
                let newMessagesView = UIView()
                cell.contentView.addSubview(newMessagesView)
                newMessagesView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    newMessagesView.topAnchor.constraint(equalTo: newMessagesView.topAnchor),
                    newMessagesView.bottomAnchor.constraint(equalTo: containerMessage.topAnchor),
                    newMessagesView.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                    newMessagesView.heightAnchor.constraint(equalToConstant: 30),
                    newMessagesView.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
                ])
                newMessagesView.backgroundColor = .greenColor
                newMessagesView.layer.cornerRadius = 15.0
                newMessagesView.clipsToBounds = true
                
                let labelNewMessages = UILabel()
                newMessagesView.addSubview(labelNewMessages)
                labelNewMessages.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    labelNewMessages.centerYAnchor.constraint(equalTo: newMessagesView.centerYAnchor),
                    labelNewMessages.centerXAnchor.constraint(equalTo: newMessagesView.centerXAnchor),
                    labelNewMessages.leadingAnchor.constraint(equalTo: newMessagesView.leadingAnchor, constant: 10),
                    labelNewMessages.trailingAnchor.constraint(equalTo: newMessagesView.trailingAnchor, constant: -10),
                ])
                labelNewMessages.textAlignment = .center
                labelNewMessages.textColor = .secondaryColor
                labelNewMessages.font = UIFont.systemFont(ofSize: 12, weight: .medium)
                labelNewMessages.text = "Unread Messages".localized()
                
            } else {
                containerMessage.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5).isActive = true
            }
            if copySession || deleteSession {
                containerMessage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 50).isActive = true
            } else {
                containerMessage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15).isActive = true
            }
            if (dataMessages[indexPath.row]["read_receipts"] as? String) == "8" || ((dataMessages[indexPath.row]["credential"] as? String) == "1" && dataMessages[indexPath.row]["lock"] as? String != "2") {
                containerMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -40).isActive = true
            } else {
                containerMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -5).isActive = true
            }
            containerMessage.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -60).isActive = true
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            if dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"]as? String == "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String != "1") {
                containerMessage.backgroundColor = .clear
            } else {
                containerMessage.backgroundColor = .whiteBubbleColor
            }
            containerMessage.layer.cornerRadius = 10.0
            containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            containerMessage.clipsToBounds = true
            
            timeMessage.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: 8).isActive = true
        }
        
        let imageStared = UIImageView()
        if dataMessages[indexPath.row]["is_stared"] as? String == "1" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String == "0") {
            cell.contentView.addSubview(imageStared)
            imageStared.translatesAutoresizingMaskIntoConstraints = false
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                imageStared.bottomAnchor.constraint(equalTo: statusMessage.topAnchor).isActive = true
                imageStared.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            } else {
                imageStared.bottomAnchor.constraint(equalTo: timeMessage.topAnchor).isActive = true
                imageStared.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: 8).isActive = true
            }
            imageStared.widthAnchor.constraint(equalToConstant: 15).isActive = true
            imageStared.heightAnchor.constraint(equalToConstant: 15).isActive = true
            imageStared.image = UIImage(systemName: "star.fill")
            imageStared.backgroundColor = .clear
            imageStared.tintColor = .systemYellow
        }
        
        if dataMessages[indexPath.row]["read_receipts"] as? String == "8" {
            let imageAckView = UIImageView()
            var imageAck = UIImage(named: "ack_icon_gray", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            if dataMessages[indexPath.row]["status"] as? String == "8" {
                imageAck = UIImage(named: "ack_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            }
            imageAckView.image = imageAck
            cell.contentView.addSubview(imageAckView)
            imageAckView.translatesAutoresizingMaskIntoConstraints = false
            imageAckView.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageAckView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                imageAckView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
                imageAckView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 30).isActive = true
            } else {
                imageAckView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
                imageAckView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -30).isActive = true
                let tap = ObjectGesture(target: self, action: #selector(tapAck(_:)))
                tap.indexPath = indexPath
                imageAckView.addGestureRecognizer(tap)
                imageAckView.isUserInteractionEnabled = true
            }
        }
        
        if (dataMessages[indexPath.row]["credential"] as? String) == "1" && (dataMessages[indexPath.row]["lock"] as? String) != "2" {
            let imageCredentialView = UIImageView()
            let imageCredential = UIImage(named: "confidential_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            imageCredentialView.image = imageCredential
            cell.contentView.addSubview(imageCredentialView)
            imageCredentialView.translatesAutoresizingMaskIntoConstraints = false
            imageCredentialView.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageCredentialView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                imageCredentialView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
                imageCredentialView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 30).isActive = true
            } else {
                imageCredentialView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
                imageCredentialView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -30).isActive = true
            }
        }
        
        let messageText = UILabel()
        messageText.numberOfLines = 0
        messageText.lineBreakMode = .byWordWrapping
        containerMessage.addSubview(messageText)
        messageText.translatesAutoresizingMaskIntoConstraints = false
        let topMarginText = messageText.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15)
        topMarginText.isActive = true
        messageText.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        messageText.font = .systemFont(ofSize: 12)
        messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
        if dataMessages[indexPath.row]["f_pin"] as? String == "-999" && (dataMessages[indexPath.row]["blog_id"] as? String) != nil && !(dataMessages[indexPath.row]["blog_id"] as! String).isEmpty && (dataMessages[indexPath.row]["message_text"] as! String).contains("Berikut QR Code dan detil booking Anda") {
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
            imageQR.image = generateQRCode(from: dataMessages[indexPath.row]["blog_id"] as! String)
        } else {
            messageText.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: -15).isActive = true
        }
        messageText.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
        var textChat = (dataMessages[indexPath.row]["message_text"] as? String) ?? ""
        if (dataMessages[indexPath.row]["lock"] != nil && (dataMessages[indexPath.row]["lock"])! as? String == "1") {
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                textChat = "🚫 _"+"You were deleted this message".localized()+"_"
            } else {
                textChat = "🚫 _"+"This message was deleted".localized()+"_"
            }
        }
        
        if dataMessages[indexPath.row]["lock"] as? String == "2" {
            textChat = "🚫 _"+"Message has expired".localized()+"_"
        }
        
        let imageSticker = UIImageView()
        if let attachmentFlag = dataMessages[indexPath.row]["attachment_flag"], let attachmentFlag = attachmentFlag as? String {
            if attachmentFlag == "27" || attachmentFlag == "26" { // live streaming
                let data = textChat
                if let json = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                    Database().database?.inTransaction({ fmdb, rollback in
                        let title = json["title"] as? String ?? ""
                        let description = json["description"] as? String ?? ""
                        let start = json["time"] as? Int64 ?? 0
                        let by = json["by"] as? String ?? ""
                        let textLS = "Live Streaming".localized()
                        var type = "*\(textLS)*"
                        if attachmentFlag == "26" {
                            let textSeminar = "Seminar".localized()
                            type = "*\(textSeminar)*"
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
            else if attachmentFlag == "11" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String != "1") && (dataMessages[indexPath.row]["lock"] as? String != "2") {
                messageText.text = ""
                topMarginText.constant = topMarginText.constant + 100
                containerMessage.addSubview(imageSticker)
                imageSticker.translatesAutoresizingMaskIntoConstraints = false
                imageSticker.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
                imageSticker.widthAnchor.constraint(equalToConstant: 80).isActive = true
                imageSticker.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                imageSticker.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                imageSticker.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                imageSticker.image = UIImage(named: (textChat.components(separatedBy: "/")[1]), in: Bundle.resourceBundle(for: Nexilis.self), with: nil) //resourcesMediaBundle
                imageSticker.contentMode = .scaleAspectFit
            }
            else {
                messageText.attributedText = textChat.richText()
            }
        } else {
            messageText.attributedText = textChat.richText()
        }
        
        messageText.isUserInteractionEnabled = false
        if !textChat.isEmpty {
            if textChat.contains("■"){
                textChat = textChat.components(separatedBy: "■")[0]
                textChat = textChat.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            let listTextEnter = textChat.split(separator: "\n")
            let finalAtribute = textChat.richText()
        }
        
        if !copySession && !deleteSession && messageText.isUserInteractionEnabled == false {
            let interaction = UIContextMenuInteraction(delegate: self)
            containerMessage.addInteraction(interaction)
            containerMessage.isUserInteractionEnabled = true
        }
        
        if isSearching && textSearch.count > 1 {
            messageText.attributedText = textChat.richText(isSearching: true, textSearch: textSearch)
            if textChat.lowercased().contains(textSearch) {
                countMatchesSearch += 1
            }
        }
        
        let stringDate = (dataMessages[indexPath.row]["server_date"] as? String) ?? ""
        if !stringDate.isEmpty {
            let date = Date(milliseconds: Int64(stringDate) ?? 100)
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
            timeMessage.text = formatter.string(from: date as Date)
            timeMessage.textColor = .lightGray
            timeMessage.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        }
//        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureCellAction))
//        panGestureRecognizer.delegate = self
//        cellMessage.addGestureRecognizer(panGestureRecognizer)
        return cell
    }
    
    @objc func tapAck(_ sender: ObjectGesture) {
        let indexPath = sender.indexPath
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath.section]})
        if dataMessages[indexPath.row]["status"] as! String == "8" {
            return
        }
        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        DispatchQueue.global().async {
            let result = Nexilis.write(message: CoreMessage_TMessageBank.getAckLocationMessage(f_pin: dataMessages[indexPath.row]["f_pin"] as! String, message_id: dataMessages[indexPath.row]["message_id"] as! String, l_pin: dataMessages[indexPath.row]["l_pin"] as! String, server_date: "\(Date().currentTimeMillis())", message_scope_id: dataMessages[indexPath.row]["message_scope_id"] as! String, longitude: "", latitude: "", description: ""))
            if result != nil {
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                            "status" : "8"
                        ], _where: "message_id = '\(dataMessages[indexPath.row]["message_id"] as! String)'")
                    } catch {
                        rollback.pointee = true
                        print("Access database error: \(error.localizedDescription)")
                    }
                })
                DispatchQueue.main.async {
                    if let index = self.dataMessages.firstIndex(where: {$0["message_id"] as? String == dataMessages[indexPath.row]["message_id"] as? String}) {
                        self.dataMessages[index]["status"] = "8"
                        let section = self.dataDates.firstIndex(of: self.dataMessages[index]["chat_date"] as! String)
                        let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[section!]}).firstIndex(where: { $0["message_id"] as! String == self.dataMessages[index]["message_id"] as! String})
                        if row != nil && section != nil {
                            self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                        }
                        self.showToast(message: "Confirmation Success.".localized(), font: UIFont.systemFont(ofSize: 12, weight: .medium), controller: self)
                    }
                }
            }
        }
    }
    
//    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        let velocity : CGPoint = gestureRecognizer.location(in: tableChatView)
//        if velocity.x < 0 {
//            return false
//        }
//        return abs(Float(velocity.x)) > abs(Float(velocity.y))
//    }
//
//    @objc func panGestureCellAction(recognizer: UIPanGestureRecognizer)  {
//        let translation = recognizer.translation(in: tableChatView)
//        let x = recognizer.view?.frame.origin.x ?? 0
//        if x >= -(recognizer.view?.frame.size.width ?? 0) * 0.05 {
//            recognizer.view?.center = CGPoint(
//                x: (recognizer.view?.center.x ?? 0) + translation.x,
//                y: (recognizer.view?.center.y ?? 0))
//            recognizer.setTranslation(CGPoint(x: 0, y: 0), in: view)
//            if (recognizer.view?.frame.origin.x ?? 0) > UIScreen.main.bounds.size.width * 0.9 {
//                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
//                    recognizer.view?.frame = CGRect(x: 0, y: recognizer.view?.frame.origin.y ?? 0, width: recognizer.view?.frame.size.width ?? 0, height: recognizer.view?.frame.size.height ?? 0)
//                })
//            }
//        }
//        if x <= -(recognizer.view?.frame.size.width ?? 0) * 0.05 {
//            let idMe = User.getMyPin() as String?
//            let indexPath = self.tableChatView.indexPath(for: recognizer.view! as! UITableViewCell)
//            let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath!.section]})
//            if (dataMessages[indexPath!.row]["f_pin"] as? String == idMe) {
//                let messageInfoVC = MessageInfo()
//                messageInfoVC.data = dataMessages[indexPath!.row]
//                self.navigationController?.pushViewController(messageInfoVC, animated: true)
//                return
//            }
//        }
//        if x >= ((recognizer.view?.frame.size.width ?? 0) * 0.2) {
//            if !hapticSwipeLeft {
//                UINotificationFeedbackGenerator().notificationOccurred(.success)
//            }
//            hapticSwipeLeft = true
//        } else if x < ((recognizer.view?.frame.size.width ?? 0) * 0.2) {
//            hapticSwipeLeft = false
//        }
//        if recognizer.state == .ended {
//            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
//                recognizer.view?.frame = CGRect(x: 0, y: recognizer.view?.frame.origin.y ?? 0, width: recognizer.view?.frame.size.width ?? 0, height: recognizer.view?.frame.size.height ?? 0)
//            } completion: { (finished) in
//                if x > ((recognizer.view?.frame.size.width ?? 0) * 0.2) {
//                    self.hapticSwipeLeft = false
//
//                }
//            }
//        }
//    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        dataDates.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = dataMessages.filter({ $0["chat_date"] as! String == dataDates[section] }).count
        return count
    }
    
    @objc func contentMessageTapped(_ sender: ObjectGesture) {
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        DispatchQueue.main.async {
            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == sender.message_id})
            if idx == nil {
                return
            }
            let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
            if section == nil {
                return
            }
            let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[section!]}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String})
            if row == nil {
                return
            }
            let indexPath = IndexPath(row: row!, section: section!)
            self.tableChatView.scrollToRow(at: indexPath, at: .middle, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let cell = self.tableChatView.cellForRow(at: indexPath) {
                    let containerMessage = cell.contentView.subviews[0]
                    let idMe = User.getMyPin() as String?
                    if (self.dataMessages[idx!]["f_pin"] as? String == idMe) {
                        containerMessage.backgroundColor = .blueBubbleColor.withAlphaComponent(0.3)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if (self.dataMessages[idx!]["attachment_flag"] as? String == "11") {
                                containerMessage.backgroundColor = .clear
                            } else {
                                containerMessage.backgroundColor = .blueBubbleColor
                            }
                        }
                    } else {
                        containerMessage.backgroundColor = .whiteBubbleColor.withAlphaComponent(0.3)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if (self.dataMessages[idx!]["attachment_flag"] as? String == "11") {
                                containerMessage.backgroundColor = .clear
                            } else {
                                containerMessage.backgroundColor = .whiteBubbleColor
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    func getWordRange(at point: CGPoint, in label: UILabel) -> Range<String.Index>? {
        guard let text = label.text else { return nil }
        
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText ?? NSAttributedString())
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.size = label.bounds.size
        
        let characterIndex = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        if characterIndex == text.count - 1 {
            return nil
        }
        var wordStartIndex = characterIndex
        while wordStartIndex > 0 && text[text.index(text.startIndex, offsetBy: wordStartIndex - 1)] != " " && text[text.index(text.startIndex, offsetBy: wordStartIndex - 1)] != "\n" {
            wordStartIndex -= 1
        }
        
        var wordEndIndex = characterIndex
        while wordEndIndex < text.count && text[text.index(text.startIndex, offsetBy: wordEndIndex)] != " " && text[text.index(text.startIndex, offsetBy: wordEndIndex)] != "\n" {
            wordEndIndex += 1
        }
        
        return text.index(text.startIndex, offsetBy: wordStartIndex)..<text.index(text.startIndex, offsetBy: wordEndIndex)
    }

    func highlightedText(for text: String, in range: Range<String.Index>, label: UILabel) -> NSAttributedString {
        let mutableAttributedString = label.attributedText!.mutableCopy() as! NSMutableAttributedString
        mutableAttributedString.addAttribute(.backgroundColor, value: UIColor.lightGray.withAlphaComponent(0.5), range: NSRange(range, in: text))
        label.isHighlighted = true
        return mutableAttributedString
    }
    
    func removeHighlightedText(for text: String, in range: Range<String.Index>, label: UILabel) -> NSAttributedString {
        let mutableAttributedString = label.attributedText!.mutableCopy() as! NSMutableAttributedString
        mutableAttributedString.removeAttribute(.backgroundColor, range: NSRange(range, in: text))
        label.isHighlighted = false
        return mutableAttributedString
    }
    
    @objc func tapMessageText(_ sender: ObjectGesture) {
        var stringURl = sender.message_id
        if stringURl.lowercased().starts(with: "www.") {
            stringURl = "https://" + stringURl.replacingOccurrences(of: "www.", with: "")
        }
        guard let url = URL(string: stringURl) else { return }
        UIApplication.shared.open(url)
    }
    
//    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        if copySession || forwardSession || deleteSession {
//            return nil
//        }
//        let idMe = User.getMyPin() as String?
//        if (dataMessages[indexPath.row]["f_pin"] as? String != idMe) {
//            return nil
//        }
//        let messageInfoVC = MessageInfo()
//        messageInfoVC.data = dataMessages[indexPath.row]
//        self.navigationController?.show(messageInfoVC, sender: nil)
//        return UISwipeActionsConfiguration()
//    }
//
//    public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        if copySession || forwardSession || deleteSession {
//            return nil
//        }
//        let action = UIContextualAction(style: .normal,
//                                        title: "") { [weak self] (action, view, completionHandler) in
//                                            self?.handleReply(indexPath: indexPath)
//                                            completionHandler(true)
//        }
//        action.backgroundColor = .white
//        action.image = UIImage(systemName: "arrowshape.turn.up.left.fill")?.withTintColor(.black, renderingMode: .alwaysOriginal)
//        return UISwipeActionsConfiguration(actions: [action])
//    }
    
    func scrollToFirstSearchMessage(indexScroll: Int = 1) {
        if textSearch.count < 2 {
            return
        }
        var lastIndex = 0
        let messageTextForSearch: [[String: Any?]] = self.dataMessages.reversed()
        for idx in 0..<messageTextForSearch.count {
            if (messageTextForSearch[idx]["message_text"] as! String).lowercased().contains(textSearch) {
                lastIndex += 1
                if lastIndex < indexScroll {
                    continue
                }
                lastScrollIdxSearch = lastIndex
                let section = self.dataDates.firstIndex(of: messageTextForSearch[idx]["chat_date"] as! String)
                if section == nil {
                    return
                }
                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[section!]}).firstIndex(where: { $0["message_id"] as? String == messageTextForSearch[idx]["message_id"] as? String})
                if row == nil {
                    return
                }
                let indexPath = IndexPath(row: row!, section: section!)
                self.tableChatView.scrollToRow(at: indexPath, at: .middle, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let cell = self.tableChatView.cellForRow(at: indexPath) {
                        let containerMessage = cell.contentView.subviews[0]
                        let idMe = User.getMyPin() as String?
                        if (messageTextForSearch[idx]["f_pin"] as? String == idMe) {
                            containerMessage.backgroundColor = .blueBubbleColor.withAlphaComponent(0.3)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if (messageTextForSearch[idx]["attachment_flag"] as? String == "11") {
                                    containerMessage.backgroundColor = .clear
                                } else {
                                    containerMessage.backgroundColor = .blueBubbleColor
                                }
                            }
                        } else {
                            containerMessage.backgroundColor = .whiteBubbleColor.withAlphaComponent(0.3)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if (messageTextForSearch[idx]["attachment_flag"] as? String == "11") {
                                    containerMessage.backgroundColor = .clear
                                } else {
                                    containerMessage.backgroundColor = .whiteBubbleColor
                                }
                            }
                        }
                    }
                }
                titleSearchMatches.isHidden = false
                if countMatchesSearch != 0 {
                    if countMatchesSearch > 1 {
                        titleSearchMatches.text = "\(lastScrollIdxSearch) " + "of".localized() + " \(countMatchesSearch) " + "matches".localized()
                    } else {
                        titleSearchMatches.text = "\(countMatchesSearch) " + "matches".localized()
                    }
                } else {
                    titleSearchMatches.text = "Not found".localized()
                }
                if lastScrollIdxSearch == countMatchesSearch || countMatchesSearch == 0 {
                    buttonUp.isEnabled = false
                    buttonUp.tintColor = .gray
                } else {
                    buttonUp.isEnabled = true
                    buttonUp.tintColor = .mainColor
                }
                if countMatchesSearch == 0 || lastScrollIdxSearch == 1 || countMatchesSearch == 1 {
                    buttonDown.isEnabled = false
                    buttonDown.tintColor = .gray
                } else {
                    buttonDown.isEnabled = true
                    buttonDown.tintColor = .mainColor
                }
                break
            }
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let indexPath = tableChatView.indexPathsForVisibleRows?.first
        if indexPath != nil {
            let headerRect = tableChatView.rectForHeader(inSection: indexPath!.section)
            let isPinned = headerRect.origin.y <= scrollView.contentOffset.y
            if listViewOnSection.count != 0 && listViewOnSection.count - 1 == indexPath!.section && indexPath!.row > 0 {
                let sect = listViewOnSection.count - 1 < currentIndexpath!.section ? listViewOnSection.count - 1 : currentIndexpath!.section
                let headerView = listViewOnSection[sect]
                headerView.isHidden = true
            }
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            let indexPath = tableChatView.indexPathsForVisibleRows?.first
            if indexPath != nil {
                let headerRect = tableChatView.rectForHeader(inSection: indexPath!.section)
                let isPinned = headerRect.origin.y <= scrollView.contentOffset.y
                if listViewOnSection.count != 0 && listViewOnSection.count - 1 == indexPath!.section && isPinned {
                    let sect = listViewOnSection.count - 1 < currentIndexpath!.section ? listViewOnSection.count - 1 : currentIndexpath!.section
                    let headerView = listViewOnSection[sect]
                    headerView.isHidden = true
                }
            }
        }
    }
}

extension ChatGPTBotView: UITextViewDelegate {
    public func textViewDidChangeSelection(_ textView: UITextView) {
        let cursorPosition = textView.caretRect(for: self.textFieldSend.selectedTextRange!.start).origin
        let currentLine = Int(cursorPosition.y / self.textFieldSend.font!.lineHeight)
        UIView.animate(withDuration: 0.3) {
            let numberOfLines = textView.textContainer.lineBreakMode == .byWordWrapping ? Int(textView.contentSize.height / textView.font!.lineHeight) - 1 : 1
            if currentLine == 0 && numberOfLines == 1 {
                self.heightTextFieldSend.constant = 40
            } else if self.heightTextFieldSend.constant < 95.0 && currentLine >= 4 {
                self.heightTextFieldSend.constant = 95.0
            } else if currentLine < 4 && numberOfLines < 5 {
                if (self.textFieldSend.text.count > 0 && self.heightTextFieldSend.constant != self.textFieldSend.contentSize.height) {
                    self.heightTextFieldSend.constant = self.textFieldSend.contentSize.height
                }
            }
        }
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        if allowTyping {
            allowTyping = false
            sendTyping(l_pin: dataPerson["f_pin"]!!, isTyping: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: {
                self.allowTyping = true
            })
        }
        if textView.text.contains("*") || textView.text.contains("_") || textView.text.contains("^") || textView.text.contains("~") {
            textView.preserveCursorPosition(withChanges: { _ in
                textView.attributedText = textView.text.richText(isEditing: true)
                return .preserveCursor
            })
        }
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black
        }
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Send message".localized()
            textView.textColor = UIColor.lightGray
        }
    }
    
    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) && (UIPasteboard.general.image != nil) {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    public override func paste(_ sender: Any?) {
        
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (self.textFieldSend.text.count == 0) {
            return text != "\n"
        }
        return true
    }
}

extension ChatGPTBotView: UISearchBarDelegate {
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        textSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        countMatchesSearch = 0
        titleSearchMatches.isHidden = true
        tableChatView.reloadData()
        scrollToFirstSearchMessage()
    }
}
