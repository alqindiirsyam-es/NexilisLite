//
//  CommunityTab.swift
//  Pods
//
//  Created by Qindi on 07/05/25.
//

import Foundation
import UIKit

public class CommunityList: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    private var communities: [CommunityModel] = []
    private let containerCommEmpty = UIView()
    
    public override func viewDidLoad() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellCommunityList")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.automaticallyAdjustsScrollIndicatorInsets = false
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        setupTableView()
        refresh()
//        NotificationCenter.default.addObserver(self, selector: #selector(onRefreshCallLog(notification:)), name: NSNotification.Name(rawValue: "refreshCallLog"), object: nil)
    }
    
    private func refresh() {
//        getData()
        
        if communities.count > 0 {
            if containerCommEmpty.isDescendant(of: view) {
                containerCommEmpty.removeFromSuperview()
            }
        } else {
            if !containerCommEmpty.isDescendant(of: view){
                view.addSubview(containerCommEmpty)
                containerCommEmpty.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor)
                
                let iconComm = UIImageView(image: UIImage(named: "pb_community_social_new", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
                containerCommEmpty.addSubview(iconComm)
                iconComm.anchor(top: containerCommEmpty.topAnchor, paddingTop: -20, centerX: containerCommEmpty.centerXAnchor, width: 250, height: 250)
                
                let titleComm = UILabel()
                containerCommEmpty.addSubview(titleComm)
                titleComm.anchor(top: iconComm.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: -20, paddingLeft: 20, paddingRight: 20)
                titleComm.font = .systemFont(ofSize: 20)
                titleComm.textColor = .label
                titleComm.numberOfLines = 0
                titleComm.text = "Stay connected with a community".localized()
                
                let descComm = UILabel()
                containerCommEmpty.addSubview(descComm)
                descComm.anchor(top: titleComm.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 8, paddingLeft: 20, paddingRight: 20)
                descComm.font = .systemFont(ofSize: 16)
                descComm.textColor = .gray
                descComm.numberOfLines = 0
                descComm.text = "Communities bring members together in topic-based groups. Any community you're added to will appear here.".localized()
                
                let buttonComm = UIButton(type: .custom)
                containerCommEmpty.addSubview(buttonComm)
                buttonComm.anchor(top: descComm.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 20, paddingLeft: 20, paddingRight: 20, height: 45)
                buttonComm.backgroundColor = .whatsappGreenColor
                buttonComm.layer.cornerRadius = 15
                buttonComm.clipsToBounds = true
                buttonComm.setTitle("New Community".localized(), for: .normal)
                buttonComm.setTitleColor(.white, for: .normal)
                buttonComm.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
                let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
                buttonComm.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
                buttonComm.imageView?.tintColor = .white
                buttonComm.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15)
                buttonComm.addTarget(self, action: #selector(rightBarButtonTapped), for: .touchUpInside)
            }
        }
        tableView.reloadData()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        navigationItem.title = "Communities".localized()
        navigationItem.hidesSearchBarWhenScrolling = true
        tabBarController?.navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.tintColor = .black
        navigationController?.navigationBar.overrideUserInterfaceStyle = .light
        self.setNeedsStatusBarAppearanceUpdate()
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black, NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)]
        let largeAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black, NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 34)]
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = attributes
        appearance.largeTitleTextAttributes = largeAttributes
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
        
//        let leftButton = UIButton(type: .system)
//        let imageLeft = UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold))
//        leftButton.setImage(imageLeft, for: .normal)
//        leftButton.tintColor = .black
//        leftButton.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
//        leftButton.layer.cornerRadius = 15
//        leftButton.clipsToBounds = true
//        leftButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
//        leftButton.addTarget(self, action: #selector(leftBarButtonTapped), for: .touchUpInside)
//        let leftBarButtonItem = UIBarButtonItem(customView: leftButton)
//        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        let rightButton = UIButton(type: .system)
        let imageRight = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold))
        rightButton.setImage(imageRight, for: .normal)
        rightButton.tintColor = .white
        rightButton.backgroundColor = .whatsappGreenColor
        rightButton.layer.cornerRadius = 15
        rightButton.clipsToBounds = true
        rightButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        rightButton.addTarget(self, action: #selector(rightBarButtonTapped), for: .touchUpInside)
        let rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    @objc func rightBarButtonTapped() {
        APIS.createCommunity()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return communities.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellCommunityList", for: indexPath)
        return cell
    }
}

