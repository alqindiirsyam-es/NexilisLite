//
//  BroadcastVariantViewController.swift
//  Qmera
//
//  Created by Kevin Maulana on 28/09/21.
//

import UIKit

class BroadcastVariantViewController: UITableViewController {

    var data: [Form] = []
    
    var selected: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseCell", for: indexPath )
        if(indexPath.item == 0){
            cell.textLabel?.text = "Message".localized()
            cell.tag = -99
        }
        else {
            cell.textLabel?.text = data[indexPath.row - 1].title
            cell.tag = Int(data[indexPath.row - 1].formId)!
        }
        cell.accessoryType = selected == cell.textLabel!.text ? .checkmark : .none
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cell = sender as! UITableViewCell
        if let destination = segue.destination as? BroadcastViewController {
            destination.broadcastVariantLabel.text = cell.textLabel?.text
            destination.broadcastVariantLabel.tag = cell.tag
            destination.form = "\(cell.tag)"
            if(destination.form != BroadcastViewController.FORM_NOT_FORM){
                destination.clearAttachment()
            }
        }
    }

}
