//
//  BackupRestoreOption.swift
//  NexilisLite
//
//  Created by Akhmad Al Qindi Irsyam on 20/02/23.
//

import UIKit

class BackupRestoreOption: UITableViewController {
    var data: [String] = ["Forever".localized(), "3 months".localized(), "a month".localized(), "a week".localized()]
    
    var selected = "M"
    
    var isSelected: ((String) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellBackupRestoreOption")
    }
    
    private func selectedOption(text: String) -> Bool {
        if selected == "F" && text == data[0] {
            return true
        } else if selected == "MMM" && text == data[1] {
            return true
        } else if selected == "M" && text == data[2] {
            return true
        } else if selected == "W" && text == data[3] {
            return true
        }
        return false
    }
    
    private func convertSelectedOption(text: String) -> String {
        if text == data[0] {
            return "F"
        } else if text == data[1] {
            return "MMM"
        } else if text == data[2] {
            return "M"
        }
        return "W"
    }
    
    public func convertSelectedOptionWithCode(code: String) -> String {
        if code == "F" {
            return data[0]
        } else if code == "MMM" {
            return data[1]
        } else if code == "M" {
            return data[2]
        }
        return data[3]
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellBackupRestoreOption", for: indexPath )
        cell.textLabel?.text = data[indexPath.row]
        cell.accessoryType = selectedOption(text: data[indexPath.row]) ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selected = convertSelectedOption(text: data[indexPath.row])
        tableView.reloadData()
        navigationController?.popViewController(animated: true, completion: { [self] in
            isSelected?(selected)
        })
    }

}
