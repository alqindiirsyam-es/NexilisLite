//
//  SignUpSignIn.swift
//  NexilisLite
//
//  Created by Akhmad Al Qindi Irsyam on 17/01/23.
//

import UIKit
import NotificationBannerSwift
import nuSDKService

public class SignUpSignIn: UIViewController {
    @IBOutlet weak var descSignUpSignIn: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: PasswordTextField!
    @IBOutlet weak var showPasswordButton: UIButton!
    @IBOutlet weak var descDisclaimer: UILabel!
    
    public var isDismiss: ((String) -> ())?
    public var forceLogin = false
    public var fromChangeNamePass = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()

//        self.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .black : .white
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
        navBarAppearance.titleTextAttributes = attributes
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationController?.navigationBar.tintColor = .white

        self.title = "Sign-Up/Sign-In".localized()
        descSignUpSignIn.text = "Please enter your nickname and your password".localized()
        descDisclaimer.text = "Disclaimer : Signing up with a nickname provides full privacy since".localized() + " \(Bundle.main.infoDictionary?["CFBundleName"] as! String) " + "does not know your identity, which is usually linked to your email account or mobile number. However, if you use a nickname, we will not be able to reset your password if you lose or forget it, so please keep your password secure.".localized()
        descDisclaimer.font = UIFont.italicSystemFont(ofSize: 14)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit".localized(), style: .plain, target: self, action: #selector(didTapSubmit(sender:)))
        
        if forceLogin {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(didTapCancel(sender:)))
        }
        
        passwordField.addPadding(.right(40))
        passwordField.isSecureTextEntry = true
        showPasswordButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        usernameField.placeholder = "Your Nickname".localized()
        passwordField.placeholder = "Password".localized()
        usernameField.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
        passwordField.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
        usernameField.addTarget(self, action: #selector(checkUsername(_:)), for: .editingChanged)
        
        showPasswordButton.addTarget(self, action: #selector(showPassword), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func didTapCancel(sender: Any) {
        self.navigationController?.dismiss(animated: true)
    }
    
    @objc func checkUsername(_ textField: UITextField) {
        let text : String! = usernameField.text
        if isValidEmail(text) {
            passwordField.isHidden = true
            showPasswordButton.isHidden = true
        } else if passwordField.isHidden {
            passwordField.isHidden = false
            showPasswordButton.isHidden = false
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
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
    
    func checkEmail(email: String) {
        if !CheckConnection.isConnectedToNetwork() || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        Nexilis.showLoader()
        DispatchQueue.global().async {
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSendOTPLogin(p_email: email), timeout: 30 * 1000) {
                if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") != "00" {
                    DispatchQueue.main.async {
                        Nexilis.hideLoader(completion: {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Unregistered email account".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        })
                    }
                } else {
                    DispatchQueue.main.async {
                        Nexilis.hideLoader(completion: {
                            self.showPageOTP(email: email)
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
    }
    
    func showPageOTP(email: String, errCode:String = "") {
        let showOTPVC = VerifyEmail()
        showOTPVC.email = email
        showOTPVC.showWrongOTP = errCode
        showOTPVC.isDismiss = { code in
            Nexilis.showLoader()
            DispatchQueue.global().async {
                if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSendVerifyChangeDevice(p_email: email, p_vercode: code), timeout: 30 * 1000) {
                    if !response.isOk() {
                        DispatchQueue.main.async {
                            Nexilis.hideLoader(completion: {
                                self.showPageOTP(email: email, errCode: response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99"))
                            })
                        }
                    } else {
                        self.deleteAllRecordDatabase()
                        let id = response.getBody(key: CoreMessage_TMessageKey.F_PIN, default_value: "")
                        let thumb = response.getBody(key: CoreMessage_TMessageKey.THUMB_ID, default_value: "")
                        if(!id.isEmpty) {
//                            Nexilis.changeUser(f_pin: id)
                            Utils.setProfile(value: true)
                            // pos registration
                            _ = Nexilis.write(message: CoreMessage_TMessageBank.getPostRegistration(p_pin: id))
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                Nexilis.hideLoader(completion: {
                                    let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                    imageView.tintColor = .white
                                    let banner = FloatingNotificationBanner(title: "Successfully Sign-In".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                    banner.show()
                                    if Nexilis.showFB {
                                        Nexilis.floatingButton.removeFromSuperview()
                                        Nexilis.floatingButton = FloatingButton()
                                        Nexilis.addFB()
                                    }
                                    if self.fromChangeNamePass{
                                        var vc = self.navigationController?.presentingViewController
                                        while vc?.presentingViewController != nil {
                                            vc = vc?.presentingViewController
                                        }
                                        vc?.dismiss(animated: true, completion: nil)
                                    }
                                    else if !self.forceLogin {
                                        self.navigationController?.popViewController(animated: true)
                                    } else {
                                        self.navigationController?.dismiss(animated: true)
                                    }
                                    self.isDismiss?(thumb)
                                })
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
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.navigationController?.present(showOTPVC, animated: true, completion: nil)
        })
    }
    
    @objc func didTapSubmit(sender: Any) {
        guard let name = usernameField.text, !name.isEmpty else {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Username can't be empty".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
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
        
        if isValidEmail(name) {
            checkEmail(email: name)
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
        if !CheckConnection.isConnectedToNetwork() || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        if Database.shared.openDatabase() == 0 {
            APIS.showRestartApp()
            return
        }
        Nexilis.showLoader()
        DispatchQueue.global().async {
            let md5Hex = password
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSignUpSignInAPI(p_name: name, p_password: md5Hex), timeout: 30 * 1000) {
                if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "20" {
                    DispatchQueue.main.async {
                        Nexilis.hideLoader(completion: {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Invalid user / Username and password does not match".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        })
                    }
                } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                    DispatchQueue.main.async {
                        Nexilis.hideLoader(completion: {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Failed, unknown user".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        })
                    }
                } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "4u" {
                    DispatchQueue.main.async {
                        Nexilis.hideLoader(completion: {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Failed, blocked user".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        })
                    }
                } else if !response.isOk() {
                    DispatchQueue.main.async {
                        Nexilis.hideLoader(completion: {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Failed".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        })
                    }
                } else {
                    let sign = response.getBody(key: CoreMessage_TMessageKey.SIGN, default_value: "")
                    if sign == "1" {
                        let id = response.getBody(key: CoreMessage_TMessageKey.F_PIN, default_value: "")
                        let f_pin = response.getBody(key: CoreMessage_TMessageKey.F_PIN_REAL, default_value: "")
                        let thumb = response.getBody(key: CoreMessage_TMessageKey.THUMB_ID, default_value: "")
                        let device_id = response.getBody(key: CoreMessage_TMessageKey.IMEI, default_value: id)
                        let last_sign = response.getBody(key: CoreMessage_TMessageKey.LAST_SIGN, default_value: "0")
                        //print("last sign: \(last_sign)")
                        if last_sign != "0" {
                            Utils.setLoginMultipleFPin(value: f_pin)
                            DispatchQueue.main.async {
                                let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Multiple Login Detected...".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
                                banner.show()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                Nexilis.hideLoader(completion: {
                                    if Nexilis.showFB {
                                        Nexilis.floatingButton.removeFromSuperview()
                                        Nexilis.floatingButton = FloatingButton()
                                        Nexilis.addFB()
                                    }
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onRefreshWebView"), object: nil, userInfo: nil)
                                    if self.fromChangeNamePass{
                                        var vc = self.navigationController?.presentingViewController
                                        while vc?.presentingViewController != nil {
                                            vc = vc?.presentingViewController
                                        }
                                        vc?.dismiss(animated: true, completion: nil)
                                    }
                                    else if !self.forceLogin {
                                        self.navigationController?.popViewController(animated: true)
                                    } else {
                                        self.navigationController?.dismiss(animated: true)
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                        let dialog = DialogUnableAccess()
                                        dialog.modalTransitionStyle = .crossDissolve
                                        dialog.modalPresentationStyle = .overCurrentContext
                                        UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                                    })
                                })
                            })
                            return
                        }
                        self.deleteAllRecordDatabase()
                        if(!id.isEmpty) {
//                            Nexilis.changeUser(f_pin: device_id)
                            SecureUserDefaults.shared.set(device_id, forKey: "device_id")
                            Utils.setProfile(value: true)
                            // pos registration
                            _ = Nexilis.write(message: CoreMessage_TMessageBank.getPostRegistration(p_pin: id))
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                Nexilis.hideLoader(completion: {
                                    let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                    imageView.tintColor = .white
                                    let banner = FloatingNotificationBanner(title: "Successfully Sign-In".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                    banner.show()
                                    if Nexilis.showFB {
                                        Nexilis.floatingButton.removeFromSuperview()
                                        Nexilis.floatingButton = FloatingButton()
                                        Nexilis.addFB()
                                    }
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onRefreshWebView"), object: nil, userInfo: nil)
                                    if self.fromChangeNamePass{
                                        var vc = self.navigationController?.presentingViewController
                                        while vc?.presentingViewController != nil {
                                            vc = vc?.presentingViewController
                                        }
                                        vc?.dismiss(animated: true, completion: nil)
                                    }
                                    else if !self.forceLogin {
                                        self.navigationController?.popViewController(animated: true)
                                    } else {
                                        self.navigationController?.dismiss(animated: true)
                                    }
                                    self.isDismiss?(thumb)
                                })
                            })
                        }
                    } else {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT * FROM BUDDY where f_pin = '\(idMe)' ") {
                                    if !cursorData.next() {
                                        _ = Nexilis.write(message: CoreMessage_TMessageBank.getPostRegistration(p_pin: idMe))
                                    } else {
                                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: ["first_name": first , "last_name": last], _where: "f_pin = '\(idMe)'")
                                    }
                                    cursorData.close()
                                }
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
                                let banner = FloatingNotificationBanner(title: "Successfully Sign-Up".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                banner.show()
                                if self.fromChangeNamePass{
                                    var vc = self.navigationController?.presentingViewController
                                    while vc?.presentingViewController != nil {
                                        vc = vc?.presentingViewController
                                    }
                                    vc?.dismiss(animated: true, completion: nil)
                                }
                                else if !self.forceLogin {
                                    self.navigationController?.popViewController(animated: true)
                                } else {
                                    self.navigationController?.dismiss(animated: true)
                                }
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

}
