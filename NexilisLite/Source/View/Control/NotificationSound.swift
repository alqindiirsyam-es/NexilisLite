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
    var lastSelectedSound = 0
    var audioPlayer: AVAudioPlayer?

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
        data.append(NotifSound(id: 001, name: "Nexilis Message (Default)", isSelected: false))
        data.append(NotifSound(id: 002, name: "Dutifully", isSelected: false))
        data.append(NotifSound(id: 003, name: "Elegant", isSelected: false))
        data.append(NotifSound(id: 004, name: "Eventually", isSelected: false))
        data.append(NotifSound(id: 005, name: "Hangover", isSelected: false))
        data.append(NotifSound(id: 006, name: "Juntos", isSelected: false))
        data.append(NotifSound(id: 007, name: "Light Hearted", isSelected: false))
        data.append(NotifSound(id: 008, name: "Magic", isSelected: false))
        data.append(NotifSound(id: 009, name: "Out of Nowhere", isSelected: false))
        data.append(NotifSound(id: 010, name: "Relax", isSelected: false))
        data.append(NotifSound(id: 011, name: "Strong Minded", isSelected: false))
        data.append(NotifSound(id: 012, name: "Swift gesture", isSelected: false))
        data.append(NotifSound(id: 013, name: "Upset", isSelected: false))
        var selectedSound: String = SecureUserDefaults.shared.value(forKey: "newNotifSoundPersonal") ?? ""
        if !isPersonal {
            selectedSound = SecureUserDefaults.shared.value(forKey: "newNotifSoundGroup") ?? ""
        }
        if !selectedSound.isEmpty {
            let selectedSoundId = Int(selectedSound.components(separatedBy: ":")[0])
            let idx = data.firstIndex(where: {$0.id == selectedSoundId})
            if idx != nil {
                data[idx!].isSelected = true
                isSelectedSound = selectedSoundId!
            } else {
                data[0].isSelected = true
                isSelectedSound = 001
            }
        } else {
            data[0].isSelected = true
            isSelectedSound = 001
        }
    }
    
    @objc func cancel(sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func save(sender: Any) {
        let idx = data.firstIndex(where: {$0.id == isSelectedSound})
        if isPersonal {
            SecureUserDefaults.shared.set("\(data[idx!].id):\(data[idx!].name)", forKey: "newNotifSoundPersonal")
        } else {
            SecureUserDefaults.shared.set("\(data[idx!].id):\(data[idx!].name)", forKey: "newNotifSoundGroup")
        }
        //stopSound
        if audioPlayer != nil && audioPlayer!.isPlaying {
            audioPlayer?.stop()
        }
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let idx = data.firstIndex(where: {$0.id == isSelectedSound})
        data[idx!].isSelected = false
        
        let idxNew = data.firstIndex(where: {$0.id == data[indexPath.row].id})
        data[idxNew!].isSelected = true
        if lastSelectedSound != 0 {
            //stopSound
            audioPlayer?.stop()
        }
        lastSelectedSound = data[indexPath.row].id
        isSelectedSound = data[indexPath.row].id
        //playSound
        var nameSound = data[indexPath.row].name.replacingOccurrences(of: " ", with: "_")
        if nameSound.contains("_(Default)") {
            nameSound = nameSound.replacingOccurrences(of: "_(Default)", with: "")
        }
        var soundURL = Bundle.resourceBundle(for: Nexilis.self).url(forResource: nameSound, withExtension: "mp3")
        if soundURL == nil {
            soundURL = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: nameSound, withExtension: "mp3")
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL!)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            
        }
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
