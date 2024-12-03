//
//  ChooserViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 08/09/21.
//

import UIKit

class AudienceViewController: UITableViewController {

    var data: [String] = ["Customer".localized(), "Team".localized(), "All User".localized(), "Group".localized(), "User".localized(), "Merchant Member".localized()]
    
    var selected: String?
    var isBroadcast = false
    
    var isDismiss: ((Int) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(!isBroadcast){
            return data.count - 1
        }
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
            destination.audience.text = cell.textLabel?.text
            destination.audience.tag = cell.tag
        }
        else if let destination = segue.destination as? BroadcastViewController {
            destination.targetAudienceLabel.text = cell.textLabel?.text
            destination.targetAudienceLabel.tag = cell.tag
            destination.dest = "\(cell.tag + 1)"
            if(destination.dest == BroadcastViewController.DESTINATION_GROUP || destination.dest == BroadcastViewController.DESTINATION_SPESIFIC) {
                destination.memberCell.isHidden = false
            }
            else {
                destination.memberCell.frame.size.height = 0.0
                destination.memberCell.isHidden = true
            }
            if(destination.dest == BroadcastViewController.DESTINATION_GROUP){
                destination.memberListLabel.text = "Groups".localized()
            }
            else{
                destination.memberListLabel.text = "Members".localized()
            }
            destination.memberTable.reloadData()
            destination.tableView.reloadData()
        }
    }
}
