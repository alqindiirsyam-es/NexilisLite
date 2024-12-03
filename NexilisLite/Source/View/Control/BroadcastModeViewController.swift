//
//  BroadcastModeTableViewController.swift
//  Qmera
//
//  Created by Kevin Maulana on 28/09/21.
//

import UIKit

class BroadcastModeViewController: UITableViewController {

    var data: [String] = ["One Time".localized(), "Daily".localized(), "Weekly".localized(), "Monthly".localized()]
    
    var selected: String?
    
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
        if let destination = segue.destination as? BroadcastViewController {
            destination.broadcastModeLabel.text = cell.textLabel?.text
            destination.broadcastModeLabel.tag = cell.tag
            destination.mode = "\(cell.tag + 1)"
            if(cell.tag == 0){
                destination.endTimeCell.isHidden = true
            }
            else {
                destination.endTimeCell.isHidden = false
            }
            destination.tableView.reloadData()
        }
    }

}
