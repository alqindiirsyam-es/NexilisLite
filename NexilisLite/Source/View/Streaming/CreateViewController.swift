//
//  CreateLiveViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 08/09/21.
//

import UIKit

class CreateViewController: UITableViewController {
    
    @IBOutlet weak var audience: UILabel!
    
    @IBOutlet weak var type: UILabel!
    
    @IBOutlet weak var streamingTitle: UITextField!
    
    @IBOutlet weak var streamingDesc: UITextView!
    
    @IBOutlet weak var streamingTag: UITextField!
    
    var isJoin = false
    
    var data: [String: Any] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Live Streaming".localized()
        
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel(sender:)))
        
        navigationController?.navigationBar.barTintColor = UIColor.black
        
        
        navigationItem.leftBarButtonItem = cancel
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done".localized(), style: .plain, target: self, action: #selector(didTapRight(sender:)))
        
        audience.text = "Customer".localized()
        type.text = "Notification".localized()
        
        if isJoin {
            navigationItem.rightBarButtonItem?.title = "Join"
            streamingTitle.isEnabled = false
            streamingDesc.isEditable = false
            streamingTag.isEnabled = false
            if let a = data["type"] as? String {
                audience.text = AudienceViewController().data[getTypeIndex(value: a)]
            }
            if let b = data["broadcast_type"] as? String {
                type.text = TypeViewController().data[getBroadcastIndex(value: b)]
            }
            if let c = data["title"] as? String {
                streamingTitle.text = c
            }
            if let d = data["description"] as? String {
                streamingDesc.text = d
            }
            if let e = data["tagline"] as? String {
                streamingTag.text = e
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if isJoin, indexPath.section == 0 {
            return nil
        }
        return indexPath
    }
    
    @objc func didTapRight(sender: Any?) {
        let controller = QmeraStreamingViewController()
        controller.isLive = !isJoin
        //print(">>>>> \(data)")
        if isJoin {
            guard let by = data["by"] as? String else {
                return
            }
            controller.data = by
        } else {
            guard let streamingTitle = streamingTitle.text else {
                return
            }
            guard let streamingDesc = streamingDesc.text else {
                return
            }
            
            let id = "LST\(Date().currentTimeMillis().toHex())"
            
            var data: [String: Any] = [:]
            data["title"] = streamingTitle
            data["description"] = streamingDesc
            data["by"] = User.getMyPin() ?? ""
            data["tagline"] = streamingTag.text ?? ""
            data["time"] = Date().currentTimeMillis()
            data["blog"] = id
            
            var type: String = "0" // Friend
            let groups: [String] = []
            let members: [String] = ["029a20f0cf"]
            switch self.audience.tag {
            case 0:
                type = "7"
            case 1:
                type = "8"
            case 2:
                type = "3"
            case 3:
                type = "6"
            case 4:
                type = "5"
            default:
                type = "0"
            }
            
            data["groups"] = groups
            data["members"] = members
            data["type"] = type
            
            var notif: String = "0"
            switch self.type.tag {
            case 0:
                notif = "1"
            default:
                notif = "2"
            }
            
            data["broadcast_type"] = notif
            
            guard let json = String(data: try! JSONSerialization.data(withJSONObject: data, options: []), encoding: String.Encoding.utf8) else {
                return
            }
            
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.createLS(title: "1~\(streamingTitle)", type: type, category: "3", tagline: streamingTag.text ?? "", notifType: notif, blogId: id, data: json)) {
                if response.getBody(key: CoreMessage_TMessageKey.ERRCOD) != "00" {
                    showToast(message: "Server Busy. Please try again.".localized(), font: UIFont.systemFont(ofSize: 12), controller: self)
                }
            } else {
                showToast(message: "No Network. Please try again.".localized(), font: UIFont.systemFont(ofSize: 12), controller: self)
            }
            controller.data = User.getMyPin()!
            controller.streamingData = data
        }
        navigationController?.show(controller, sender: nil)
    }
    
    @objc func didTapCancel(sender: AnyObject) {
        navigationController?.popViewController(animated: true)
//        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func getTypeIndex(value: String) -> Int {
        var type = 0
        switch value {
        case "7":
            type = 0
        case "8":
            type = 1
        case "3":
            type = 2
        case "6":
            type = 3
        case "5":
            type = 4
        default:
            type = 0
        }
        return type
    }
    
    func getBroadcastIndex(value: String) -> Int {
        var notif = 0
        switch value {
        case "1":
            notif = 0
        default:
            notif = 1
        }
        return notif
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "audience" {
            let destination = segue.destination as! AudienceViewController
            destination.selected = audience.text
        } else if segue.identifier == "promotion" {
            let destination = segue.destination as! TypeViewController
            destination.selected = type.text
        }
    }
    
    @IBAction func result(unwind segue: UIStoryboardSegue) {
        
    }
}
