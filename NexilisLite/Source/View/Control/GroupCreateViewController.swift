//
//  GroupCreateViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 24/09/21.
//

import UIKit

class GroupCreateViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var subGroup: UITextField!
    
    private let id = Date().currentTimeMillis().toHex()
    
    var isDismiss: ((String) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Create Group".localized()
        
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
        navBarAppearance.titleTextAttributes = attributes
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(cancel(sender:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save".localized(), style: .done, target: self, action: #selector(save(sender:)))
        navigationItem.rightBarButtonItem?.isEnabled = false
        name.placeholder = "Title".localized() + "*"
        subGroup.placeholder = "Sub Group".localized() + " " + "(" + "Optional".localized() + ")"
        name.delegate = self
        subGroup.delegate = self
        
        name.addTarget(self, action: #selector(onTextChanged(sender:)), for: .editingChanged)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let currentText = textField.text else { return true }
        let newLength = currentText.count + string.count - range.length
        return newLength <= 100
    }
    
    func submit(completion: @escaping (Bool) -> ()) {
        let groupName = self.name.text!
        DispatchQueue.global().async {
            if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getCreateGroup(p_group_id: self.id, p_group_name: groupName)), response.isOk() {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    @objc func onTextChanged(sender: Any) {
        if let text = name.text?.trimmingCharacters(in: .whitespaces), text.isEmpty {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    @objc func cancel(sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func save(sender: Any) {
        Nexilis.showLoader()
        submit { result in
            DispatchQueue.main.async {
                if result {
                    if let subGroup = self.subGroup.text, !subGroup.isEmpty {
                        DispatchQueue.global().async {
                            let idSub = Date().currentTimeMillis().toHex()
                            if let result = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getCreateSubGroup(group_id: idSub, group_name: subGroup, parent_id: self.id, level: "2")), result.isOk() {
                                DispatchQueue.main.async {
                                    Nexilis.hideLoader {
                                        self.navigationController?.dismiss(animated: true, completion: nil)
                                        self.isDismiss?(self.id)
                                    }
                                }
                            }
                        }
                    } else {
                        Nexilis.hideLoader {
                            self.navigationController?.dismiss(animated: true, completion: nil)
                            self.isDismiss?(self.id)
                        }
                    }
                } else {
                    self.view.makeToast("Server busy, please try again later".localized(), duration: 3)
                }
            }
        }
    }
    
}
