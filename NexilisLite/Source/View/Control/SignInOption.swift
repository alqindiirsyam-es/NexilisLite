//
//  SignInOption.swift
//  Pods
//
//  Created by Qindi on 16/06/25.
//

import UIKit
import Foundation

public class SignInOption: UIViewController {
    public var forceLogin = false
    public var forceSignIn = false
    
    private let containerView = UIStackView()
    
    public override func viewDidLoad() {
        if forceSignIn {
            self.title = "Sign-In Method".localized()
        } else {
            self.title = "Sign-Up/Sign-In Method".localized()
        }
        if forceLogin && !forceSignIn {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(didTapCancel(sender:)))
        }
        self.navigationController?.navigationBar.topItem?.backButtonTitle = ""
        createBody()
        if Nexilis.checkingAccess(key: "sign_in_up_msisdn") {
            addButton(type: 0)
        }
        if Nexilis.checkingAccess(key: "sign_in_up_email") {
            addButton(type: 1)
        }
        if Nexilis.checkingAccess(key: "sign_in_up_username") {
            addButton(type: 2)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
        navBarAppearance.titleTextAttributes = attributes
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationController?.navigationBar.tintColor = .white
    }
    
    private func createBody() {
        let iconIV = UIImageView(image: UIImage(named: "pb_user", in: Bundle.resourceBundle(for: Nexilis.self), with: nil))
        self.view.addSubview(iconIV)
        iconIV.anchor(top: self.view.safeAreaLayoutGuide.topAnchor, paddingTop: 20, centerX: self.view.centerXAnchor, width: 250, height: 200)
        
        let title = UILabel()
        self.view.addSubview(title)
        title.anchor(top: iconIV.bottomAnchor, paddingTop: 10, centerX: iconIV.centerXAnchor)
        if forceSignIn {
            title.text = "Choose your Sign-In method :".localized()
        } else {
            title.text = "Choose your Sign-Up or Sign-In method :".localized()
        }
        title.font = .systemFont(ofSize: 14)
        
        let bottomTitle = UILabel()
        self.view.addSubview(bottomTitle)
        bottomTitle.anchor(bottom: self.view.bottomAnchor, paddingBottom: 10, centerX: iconIV.centerXAnchor)
        bottomTitle.text = "Powered by Nexilis".localized()
        bottomTitle.font = .systemFont(ofSize: 13)
        
        self.view.addSubview(containerView)
        let countData = APIS.checkSignMethod().0
        let heightButton = 60 * CGFloat(countData)
        containerView.anchor(top: title.bottomAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: 10, paddingLeft: 20, paddingRight: 20, height: heightButton + 30)
        containerView.spacing = 10
        containerView.axis = .vertical
        containerView.distribution = .fillEqually
    }
    
    private func addButton(type: Int) {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: containerView.bounds.size.width, height: 60)
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.backgroundColor = .whiteBubbleColor
        button.tag = type
        button.addTarget(self, action: #selector(didTapSignIn), for: .touchUpInside)
        
        var image = UIImage(named: "pb_ic_msisdn", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
        var title = "Phone Number (MSISDN)".localized()
        if type == 1 {
            image = UIImage(named: "pb_stg_email", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
            title = "Email".localized()
        } else if type == 2 {
            image = UIImage(named: "pb_ic_name", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
            title = "Username".localized()
        }
        
        let imageView = UIImageView(image: image)
        button.addSubview(imageView)
        imageView.anchor(left: button.leftAnchor, paddingLeft: 20, centerY: button.centerYAnchor, width: 40, height: 40)
        imageView.layer.cornerRadius = 20
        imageView.backgroundColor = .white
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .label
        titleLabel.font = .boldSystemFont(ofSize: 14)
        button.addSubview(titleLabel)
        titleLabel.anchor(left: imageView.rightAnchor, right: button.rightAnchor, paddingLeft: 10, paddingRight: 20, centerY: button.centerYAnchor)
        
        containerView.addArrangedSubview(button)
    }
    
    @objc func didTapSignIn(sender: UIButton) {
        if !forceSignIn {
            let vc = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "signupsignin") as! SignUpSignIn
            if sender.tag == 0 {
                vc.isMSISDN = true
            } else if sender.tag == 1 {
                vc.isEmail = true
            }
            vc.forceLogin = self.forceLogin
            self.show(vc, sender: nil)
        } else {
            let vc = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "changeDevice") as! ChangeDeviceViewController
            if sender.tag == 0 {
                vc.isMSISDN = true
            } else if sender.tag == 1 {
                vc.isEmail = true
            }
            vc.forceLogin = self.forceLogin
            self.show(vc, sender: nil)
        }
    }
    
    @objc func didTapCancel(sender: Any) {
        self.navigationController?.dismiss(animated: true)
    }
}
