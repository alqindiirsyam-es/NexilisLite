//
//  NotificationSound.swift
//  NexilisLite
//
//  Created by Akhmad Al Qindi Irsyam on 28/11/22.
//

import UIKit
import AVFoundation

public class NotificationSound: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    public var isPersonal = true
    let tableView = UITableView()
    var data: [NotifSound] = []
    var isSelectedSound = 0

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0), NSAttributedString.Key.foregroundColor: UIColor.white]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
        navBarAppearance.titleTextAttributes = attributes
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellNotifSound")
        
        tableView.delegate = self
        tableView.dataSource = self

        self.title = "Notification Message(s)".localized()
        if !isPersonal {
            self.title = "Notification Message(s) Group".localized()
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(cancel(sender:)))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save".localized(), style: .plain, target: self, action: #selector(save(sender:)))
        data.append(NotifSound(id: 1007, name: "sms-received1 (Default)", isSelected: false))
        data.append(NotifSound(id: 1008, name: "sms-received2", isSelected: false))
        data.append(NotifSound(id: 1009, name: "sms-received3", isSelected: false))
        data.append(NotifSound(id: 1010, name: "sms-received4", isSelected: false))
        data.append(NotifSound(id: 1013, name: "sms-received5", isSelected: false))
        data.append(NotifSound(id: 1014, name: "sms-received6", isSelected: false))
        var selectedSound: String = SecureUserDefaults.shared.value(forKey: "notifSoundPersonal") ?? ""
        if !isPersonal {
            selectedSound = SecureUserDefaults.shared.value(forKey: "notifSoundGroup") ?? ""
        }
        if !selectedSound.isEmpty {
            let selectedSoundId = Int(selectedSound.components(separatedBy: ":")[0])
            let idx = data.firstIndex(where: {$0.id == selectedSoundId})
            if idx != nil {
                data[idx!].isSelected = true
                isSelectedSound = selectedSoundId!
            } else {
                data[0].isSelected = true
                isSelectedSound = 1007
            }
        } else {
            data[0].isSelected = true
            isSelectedSound = 1007
        }
    }
    
    @objc func cancel(sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func save(sender: Any) {
        let idx = data.firstIndex(where: {$0.id == isSelectedSound})
        if isPersonal {
            SecureUserDefaults.shared.set("\(data[idx!].id):\(data[idx!].name)", forKey: "notifSoundPersonal")
        } else {
            SecureUserDefaults.shared.set("\(data[idx!].id):\(data[idx!].name)", forKey: "notifSoundGroup")
        }
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let idx = data.firstIndex(where: {$0.id == isSelectedSound})
        data[idx!].isSelected = false
        
        let idxNew = data.firstIndex(where: {$0.id == data[indexPath.row].id})
        data[idxNew!].isSelected = true
        isSelectedSound = data[indexPath.row].id
        
        let systemSoundID: SystemSoundID = SystemSoundID(isSelectedSound)
        AudioServicesPlaySystemSound(systemSoundID)
        tableView.reloadData()
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellNotifSound", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = data[indexPath.row].name
        cell.contentConfiguration = content
        cell.accessoryType = data[indexPath.row].isSelected ? .checkmark : .none
        cell.selectionStyle = .none
        return cell
    }
}
