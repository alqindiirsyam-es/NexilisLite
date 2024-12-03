//
//  ChooserViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 08/09/21.
//

import UIKit

class TypeViewController: UITableViewController {
    
    var data: [String] = ["Notification".localized(), "In App".localized()]
    
    var selected: String?
    
    var isDismiss: ((Int) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseCell", for: indexPath )
        let selectedCell = data[indexPath.row]
        cell.textLabel?.text = selectedCell
        cell.accessoryType = selected == selectedCell ? .checkmark : .none
        cell.tag = indexPath.row
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cell = sender as! UITableViewCell
        isDismiss?(cell.tag)
        if let destination = segue.destination as? CreateViewController {
            destination.type.text = cell.textLabel?.text
            destination.type.tag = cell.tag
        }
        else if let destination = segue.destination as? BroadcastViewController {
            destination.broadcastTypeLabel.text = cell.textLabel?.text
            destination.broadcastTypeLabel.tag = cell.tag
        }
    }
}
