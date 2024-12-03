//
//  WorkingAreaPicker.swift
//  NexilisLite
//
//  Created by Qindi on 26/07/22.
//

import UIKit

class WorkingAreaPicker: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    let subContainerView = UIView()
    lazy var searchBar:UISearchBar = UISearchBar()
    var dataWorkingArea: [WorkingArea] = []
    let tableView = UITableView()
    
    public var selectedData: ((WorkingArea) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

//        self.view.backgroundColor = .black.withAlphaComponent(0.3)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        let containerView = UIView()
        view.addSubview(containerView)
        containerView.anchor(centerX: view.centerXAnchor, centerY: view.centerYAnchor, width: view.bounds.width - 40, height: view.bounds.height - 100)
        containerView.backgroundColor = .white.withAlphaComponent(0.9)
        
        subContainerView.backgroundColor = .clear
        containerView.addSubview(subContainerView)
        subContainerView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 20.0, paddingLeft: 10.0, paddingBottom: 20.0, paddingRight: 10.0)
        
        let buttonClose = UIButton(type: .close)
        buttonClose.frame.size = CGSize(width: 30, height: 30)
        buttonClose.layer.cornerRadius = 15.0
        buttonClose.clipsToBounds = true
        buttonClose.backgroundColor = .secondaryColor.withAlphaComponent(0.5)
        buttonClose.addTarget(self, action: #selector(close), for: .touchUpInside)
        containerView.addSubview(buttonClose)
        buttonClose.anchor(top: containerView.topAnchor, right: containerView.rightAnchor, width: 30, height: 30)
        
        let titleWA = UILabel()
        titleWA.font = .systemFont(ofSize: 18, weight: .bold)
        titleWA.text = "Working Area".localized()
        titleWA.textAlignment = .center
        subContainerView.addSubview(titleWA)
        titleWA.anchor(top: subContainerView.topAnchor, left: subContainerView.leftAnchor, right: subContainerView.rightAnchor)
        
        searchBar.searchBarStyle = UISearchBar.Style.default
        searchBar.placeholder = " Search..."
        searchBar.sizeToFit()
        searchBar.isTranslucent = true
        searchBar.updateHeight(height: 36, radius: 18)
        searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        searchBar.delegate = self
        subContainerView.addSubview(searchBar)
        searchBar.anchor(top: titleWA.bottomAnchor, left: subContainerView.leftAnchor, right: subContainerView.rightAnchor, paddingTop: 10.0)
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellWorkingArea")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        self.view.addSubview(tableView)
        tableView.anchor(top: searchBar.bottomAnchor, left: subContainerView.leftAnchor, bottom: subContainerView.bottomAnchor, right: subContainerView.rightAnchor, paddingBottom: 10.0)
        
        dataWorkingArea = WorkingArea.getData(name: "")
        
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @objc func close() {
        self.dismiss(animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        DispatchQueue.main.async {
            self.dataWorkingArea = WorkingArea.getData(name: searchText)
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedData?(self.dataWorkingArea[indexPath.row])
        self.dismiss(animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataWorkingArea.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellWorkingArea", for: indexPath as IndexPath)
        cell.textLabel!.text = dataWorkingArea[indexPath.row].name
        cell.backgroundColor = .clear
        return cell
    }

}
