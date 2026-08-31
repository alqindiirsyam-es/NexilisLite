//
//  ChangePasswordViewController.swift
//  NexilisLite
//
//  Created by Qindi on 23/03/22.
//

import UIKit
@_implementationOnly import NotificationBannerSwift
class ChangePasswordViewController: UIViewController {
    @IBOutlet weak var oldPassField: PasswordTextField!
    @IBOutlet weak var newPassField: PasswordTextField!
    @IBOutlet weak var showOldPassButton: UIButton!
    @IBOutlet weak var showNewPassButton: UIButton!
    @IBOutlet weak var labelDesc: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Change Password".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save".localized(), style: .plain, target: self, action: #selector(didTapNext(sender:)))
        
        oldPassField.addPadding(.right(40))
        oldPassField.isSecureTextEntry = false
        
        newPassField.addPadding(.right(40))
        newPassField.isSecureTextEntry = false
        
        oldPassField.placeholder = "Old Password".localized()
        newPassField.placeholder = "New Password".localized()
        
        showOldPassButton.addTarget(self, action: #selector(showOldPassword), for: .touchUpInside)
        showNewPassButton.addTarget(self, action: #selector(showNewPassword), for: .touchUpInside)
        
        labelDesc.text = "Change password to keep your account secure".localized()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @objc func didTapNext(sender: Any) {
        guard let oldPassword = oldPassField.text, !oldPassword.trimmingCharacters(in: .whitespaces).isEmpty else {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Old password can't be empty".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        if oldPassword.count < 6 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Old password min 6 character".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
//            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
//            imageView.tintColor = .white
//            let banner = FloatingNotificationBanner(title: "Incorrect old password".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
//            banner.show()
//            return
//        }
        guard let newPassword = newPassField.text, !newPassword.trimmingCharacters(in: .whitespaces).isEmpty else {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "New password can't be empty".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        if newPassword.count < 6 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "New password min 6 character".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        let idMe = User.getMyPin()!
        DispatchQueue.global().async {
            let tMessage = CoreMessage_TMessageBank.getChangePersonInfo_New(p_f_pin: idMe)
            let md5HexOld = oldPassword
            let md5HexNew = newPassword
            tMessage.mBodies[CoreMessage_TMessageKey.PSWD] = md5HexNew
            tMessage.mBodies[CoreMessage_TMessageKey.PSWD_OLD] = md5HexOld
            if let resp = Nexilis.writeAndWait(message: tMessage){
                if resp.isOk() {
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Successfully changed password".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                        banner.show()
                        self.navigationController?.popViewController(animated: true)
                    }
                } else {
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: resp.getBody(key: CoreMessage_TMessageKey.MESSAGE_TEXT), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                }
            }
        }
    }
    
    @objc func showOldPassword() {
        if oldPassField.isSecureTextEntry {
            oldPassField.isSecureTextEntry = false
            showOldPassButton.setImage(UIImage(systemName: "eye.fill"), for: .normal)
        } else {
            oldPassField.isSecureTextEntry = true
            showOldPassButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        }
    }
    
    @objc func showNewPassword() {
        if newPassField.isSecureTextEntry {
            newPassField.isSecureTextEntry = false
            showNewPassButton.setImage(UIImage(systemName: "eye.fill"), for: .normal)
        } else {
            newPassField.isSecureTextEntry = true
            showNewPassButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        }
    }

}
