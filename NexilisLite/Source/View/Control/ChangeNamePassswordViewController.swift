//
//  ChangeNamePassswordViewController.swift
//  NexilisLite
//
//  Created by Qindi on 22/03/22.
//

import UIKit
@_implementationOnly import NotificationBannerSwift
import nuSDKService

public class ChangeNamePassswordViewController: UIViewController {
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var showPasswordButton: UIButton!
    @IBOutlet weak var descField: UILabel!
    @IBOutlet weak var loginQuest: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    
    public var fromSetting = false
    public var isSuccess: (() -> ())?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white

        self.title = "Set Profile".localized()
        if !fromSetting {
            let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0), NSAttributedString.Key.foregroundColor: UIColor.white]
            self.navigationController?.navigationBar.titleTextAttributes = attributes
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(didTapExit(sender:)))
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save".localized(), style: .plain, target: self, action: #selector(didTapSave(sender:)))
        
        passwordField.addPadding(.right(40))
        passwordField.isSecureTextEntry = true
        showPasswordButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        
        showPasswordButton.addTarget(self, action: #selector(showPassword), for: .touchUpInside)
        usernameField.placeholder = "Username".localized()
        passwordField.placeholder = "Password".localized()
        descField.text = "Please enter your desired Username and Password".localized()
        
        loginQuest.text = "Or do you have an account".localized()
        loginButton.setTitle(("Sign-In".localized()).uppercased(), for: .normal)
        loginButton.addTarget(self, action: #selector(showLogin), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func showLogin() {
//        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "changeDevice") as! ChangeDeviceViewController
//        controller.fromChangeNamePass = true
//        navigationController?.show(controller, sender: nil)
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @objc func didTapExit(sender: Any) {
        if fromSetting {
            self.navigationController?.popViewController(animated: true)
            self.isSuccess?()
        } else {
            let vc = self.navigationController?.presentingViewController
            vc?.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func didTapSave(sender: Any) {
        guard let name = usernameField.text, !name.isEmpty else {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Username can't be empty".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        if !name.matches("^[a-zA-Z0-9 ]*$") {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Contains prohibited characters. Only alphabetic characters are allowed.".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        guard let password = passwordField.text, !password.isEmpty else {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Password can't be empty".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        if password.count < 6 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Password min 6 character".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        let a = name.split(separator: " ", maxSplits: 1)
        let first = String(a[0])
        let last = a.count == 2 ? String(a[1]) : ""
        
        if first.count > 24 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "First name is too long".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        
        if last.count > 24 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Last name is too long".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        
        let idMe = User.getMyPin()!
        
        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        Nexilis.showLoader()
        DispatchQueue.global().async {
            if let resp = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSendOTPChangeProfile(name: first + " " + last, type: "2")) {
                if resp.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "1a" {
                    DispatchQueue.main.async {
                        Nexilis.hideLoader(completion: {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Username has already been registered. Please use another username".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        })
                    }
                } else if resp.isOk() {
                    let md5Hex = password
                    let tMessage = CoreMessage_TMessageBank.getChangePersonInfo_New(p_f_pin: idMe)
                    tMessage.mBodies[CoreMessage_TMessageKey.FIRST_NAME] = first
                    tMessage.mBodies[CoreMessage_TMessageKey.LAST_NAME] = last
                    tMessage.mBodies[CoreMessage_TMessageKey.PSWD] = md5Hex
                    tMessage.mBodies[CoreMessage_TMessageKey.PSWD_OLD] = ""
                    if let resp2 = Nexilis.writeAndWait(message: tMessage){
                        if resp2.isOk() {
                            Database.shared.database?.inTransaction({ fmdb, rollback in
                                do {
                                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: ["first_name": first , "last_name": last], _where: "f_pin = '\(idMe)'")
                                } catch {
                                    rollback.pointee = true
                                    print("Access database error: \(error.localizedDescription)")
                                }
                            })
                            Utils.setProfile(value: true)
        //                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateFifthTab"), object: nil, userInfo: nil)
                            DispatchQueue.main.async {
                                Nexilis.hideLoader(completion: {
                                    let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                    imageView.tintColor = .white
                                    let banner = FloatingNotificationBanner(title: "Successfully changed".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                    banner.show()
                                    self.didTapExit(sender: "exit")
                                })
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            Nexilis.hideLoader(completion: {
                                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                                banner.show()
                            })
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    Nexilis.hideLoader(completion: {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    })
                }
            }
        }
    }
    
    @objc func showPassword() {
        if passwordField.isSecureTextEntry {
            passwordField.isSecureTextEntry = false
            showPasswordButton.setImage(UIImage(systemName: "eye.fill"), for: .normal)
        } else {
            passwordField.isSecureTextEntry = true
            showPasswordButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        }
    }

}

public class PasswordTextField: UITextField {

    public override var isSecureTextEntry: Bool {
        didSet {
            if isFirstResponder {
                _ = becomeFirstResponder()
                //MARK:- Do something what you want
            }
        }
    }

    public override func becomeFirstResponder() -> Bool {

        let success = super.becomeFirstResponder()
        if isSecureTextEntry, let text = self.text {
            self.text?.removeAll()
            insertText(text)
        }
         return success
    }
}
