//
//  SignUpSignIn.swift
//  NexilisLite
//
//  Created by Akhmad Al Qindi Irsyam on 17/01/23.
//

import UIKit
import NotificationBannerSwift
import nuSDKService
import FirebaseAuth

public class SignUpSignIn: UIViewController {
    @IBOutlet weak var descSignUpSignIn: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: PasswordTextField!
    @IBOutlet weak var showPasswordButton: UIButton!
    @IBOutlet weak var descDisclaimer: UILabel!
    @IBOutlet weak var topConstDesc: NSLayoutConstraint!
    
    public var forceLogin = false
    public var isEmail = false
    public var isMSISDN = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()

//        self.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .black : .white
        var textTitle = "Please enter your nickname and your password".localized()
        var subTitle = "Disclaimer : Signing up with a nickname provides full privacy since".localized() + " \(Bundle.main.infoDictionary?["CFBundleName"] as! String) " + "does not know your identity, which is usually linked to your email account or mobile number. However, if you use a nickname, we will not be able to reset your password if you lose or forget it, so please keep your password secure.".localized()
        var textPlaceHolder = "Your Nickname".localized()
        if isEmail {
            textTitle = "Please enter your registered email address.".localized()
            subTitle = ""
            textPlaceHolder = "Your Email".localized()
        } else if isMSISDN {
            textTitle = "Please enter your registered phone number.".localized()
            subTitle = ""
            textPlaceHolder = "Your Phone Number (082...)".localized()
        }
        descSignUpSignIn.text = textTitle
        descDisclaimer.text = subTitle
        descDisclaimer.font = UIFont.italicSystemFont(ofSize: 14)
        
        passwordField.addPadding(.right(40))
        passwordField.isSecureTextEntry = true
        showPasswordButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        usernameField.placeholder = textPlaceHolder
        passwordField.placeholder = "Password".localized()
        usernameField.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
        passwordField.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
        usernameField.addTarget(self, action: #selector(checkUsername(_:)), for: .editingChanged)
        
        showPasswordButton.addTarget(self, action: #selector(showPassword), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        if isEmail || isMSISDN {
            self.title = "Sign-In".localized()
            passwordField.isHidden = true
            showPasswordButton.isHidden = true
            if isMSISDN{
                usernameField.keyboardType = .numberPad
            }
        } else {
            self.title = "Sign-Up/Sign-In".localized()
        }
        let controllers = self.navigationController?.viewControllers
        if forceLogin && (controllers!.count < 2 || !(controllers![controllers!.count - 2] is SignInOption)) {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(didTapCancel(sender:)))
        }
        self.navigationController?.navigationBar.topItem?.backButtonTitle = ""
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
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit".localized(), style: .plain, target: self, action: #selector(didTapSubmit(sender:)))
    }
    
    @objc func didTapCancel(sender: Any) {
        self.navigationController?.dismiss(animated: true)
    }
    
    @objc func checkUsername(_ textField: UITextField) {
//        let text : String! = usernameField.text
//        if isValidEmail(text) {
//            passwordField.isHidden = true
//            showPasswordButton.isHidden = true
//        } else if passwordField.isHidden {
//            passwordField.isHidden = false
//            showPasswordButton.isHidden = false
//        }
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
            self.showFailedSignUpIn(title: "Check your connection".localized(), withLoader: false)
            return
        }
        Nexilis.showLoader()
        DispatchQueue.global().async {
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSendOTPLogin(p_email: email), timeout: 30 * 1000) {
                if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") != "00" {
                    DispatchQueue.main.async {
                        self.showFailedSignUpIn(title: "Unregistered email account".localized())
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
                    self.showFailedSignUpIn(title: "Unable to access servers. Try again later".localized())
                }
            }
        }
    }
    
    func checkNumber(number: String) {
        var number = number
        if number.hasPrefix("0") {
            number = number.replacingCharacters(in: number.startIndex...number.startIndex, with: "+62")
        }
        if !CheckConnection.isConnectedToNetwork() || API.nGetCLXConnState() == 0 {
            self.showFailedSignUpIn(title: "Check your connection".localized(), withLoader: false)
            return
        }
        self.sendOTP(to: number)
    }
    
    func sendOTP(to phoneNumber: String) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                UIApplication.shared.visibleViewController?.view.makeToast("Error sending OTP: \(error)".localized(), duration: 3, position: .center)
                return
            }

            Utils.setUserMSISDN(value: verificationID ?? "")
            self.showPageOTP(phone: phoneNumber)
        }
    }
    
    func verifyOTP(_ code: String, number: String, privateKey: SecKey) {
        let verificationID = Utils.getUserMSISDN()
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )

        Auth.auth().signIn(with: credential) { authResult, error in
            if error != nil {
                self.showFailedSignUpIn(title: "Invalid OTP".localized())
                self.showPageOTP(phone: number)
                return
            }

            DispatchQueue.global().async {
                if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChalanger()) {
                    if response.isOk() {
                        let data = response.getBody(key: CoreMessage_TMessageKey.DATA, default_value: "")
                        if data.isEmpty {
                            DispatchQueue.main.async {
                                self.showFailedSignUpIn(title: "Failed to get auth, please try again".localized())
                            }
                            return
                        }
                        var pk = ""
                        var sign = ""
                        let df = HMACDeviceFingerprintNexilis.generate()
                        if let dataSign = "\(data)!\(df)".data(using: .utf8) {
                            if let signature = KeyManagerNexilis.sign(data: dataSign, privateKey: privateKey) {
                                sign = signature.base64EncodedString()
                            }
                        }
                        if let publicKey = KeyManagerNexilis.getRSAX509PublicKeyBase64(privateKey: privateKey) {
                            pk = publicKey
                        }
                        if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSendVerifyChangeDevice(p_email: "", p_vercode: "", number: number, deviceFingerprint: df, publicKey: pk, signature: sign), timeout: 30 * 1000) {
                            if !response.isOk() {
                                DispatchQueue.main.async {
                                    DispatchQueue.main.async {
                                        self.showFailedSignUpIn(title: "Failed".localized())
                                    }
                                }
                            } else {
                                self.successSubmit(response: response, first: "", last: "", number: number)
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.showFailedSignUpIn(title: "Unable to access servers. Try again later".localized())
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.showFailedSignUpIn(title: "Failed to get auth, please try again".localized())
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showFailedSignUpIn(title: "Unable to access servers. Try again later".localized())
                    }
                }
            }
        }
    }
    
    func showPageOTP(email: String = "", phone: String = "", errCode:String = "") {
        let showOTPVC = VerifyEmail()
        showOTPVC.email = email
        showOTPVC.msisdn = phone
        showOTPVC.isMSISDN = !phone.isEmpty
        showOTPVC.showWrongOTP = errCode
        showOTPVC.isDismiss = { code in
            if !CheckConnection.isConnectedToNetwork() || API.nGetCLXConnState() == 0 {
                self.showFailedSignUpIn(title: "Check your connection".localized(), withLoader: false)
                return
            }
            if KeyManagerNexilis.hasGeneratedKey() {
                KeyManagerNexilis.deleteKey()
                KeyManagerNexilis.deleteMarker()
            }
            KeyManagerNexilis.generateKey()
            KeyManagerNexilis.saveMarker()
            guard let privateKey = KeyManagerNexilis.getPrivateKey() else {
                KeyManagerNexilis.deleteKey()
                KeyManagerNexilis.deleteMarker()
                UIApplication.shared.visibleViewController?.view.makeToast("Biometric or passcode authentication required".localized(), duration: 3, position: .center)
                return
            }
            if Database.shared.openDatabase() == 0 {
                APIS.showRestartApp()
                KeyManagerNexilis.deleteKey()
                KeyManagerNexilis.deleteMarker()
                return
            }
            Nexilis.showLoader()
            if !phone.isEmpty {
                self.verifyOTP(code, number: phone, privateKey: privateKey)
                return
            }
            DispatchQueue.global().async {
                if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChalanger()) {
                    if response.isOk() {
                        let data = response.getBody(key: CoreMessage_TMessageKey.DATA, default_value: "")
                        if data.isEmpty {
                            DispatchQueue.main.async {
                                self.showFailedSignUpIn(title: "Failed to get auth, please try again".localized())
                            }
                            return
                        }
                        var pk = ""
                        var sign = ""
                        let df = HMACDeviceFingerprintNexilis.generate()
                        if let dataSign = "\(data)!\(df)".data(using: .utf8) {
                            if let signature = KeyManagerNexilis.sign(data: dataSign, privateKey: privateKey) {
                                sign = signature.base64EncodedString()
                            }
                        }
                        if let publicKey = KeyManagerNexilis.getRSAX509PublicKeyBase64(privateKey: privateKey) {
                            pk = publicKey
                        }
                        if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSendVerifyChangeDevice(p_email: email, p_vercode: code, deviceFingerprint: df, publicKey: pk, signature: sign), timeout: 30 * 1000) {
                            if !response.isOk() {
                                DispatchQueue.main.async {
                                    self.showPageOTP(email: email, errCode: response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99"))
                                }
                            } else {
                                self.successSubmit(response: response, first: "", last: "", email: email)
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.showFailedSignUpIn(title: "Unable to access servers. Try again later".localized())
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.showFailedSignUpIn(title: "Failed to get auth, please try again".localized())
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showFailedSignUpIn(title: "Unable to access servers. Try again later".localized())
                    }
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.navigationController?.present(showOTPVC, animated: true, completion: nil)
        })
    }
    
    private func showFailedSignUpIn(title: String, withLoader: Bool = true) {
        KeyManagerNexilis.deleteKey()
        KeyManagerNexilis.deleteMarker()
        if withLoader {
            Nexilis.hideLoader(completion: {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: title, subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
            })
        } else {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: title, subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
        }
    }
    
    @objc func didTapSubmit(sender: Any) {
        guard let name = usernameField.text, !name.isEmpty else {
            var text = "Username"
            if isEmail {
                text = "Email"
            } else if isMSISDN {
                text = "Phone Number"
            }
            self.showFailedSignUpIn(title: "\(text) can't be empty".localized(), withLoader: false)
            return
        }
        
        if isEmail {
            if !isValidEmail(name) {
                self.showFailedSignUpIn(title: "Invalid email format. Please enter a valid email address".localized(), withLoader: false)
            } else {
                checkEmail(email: name)
            }
            return
        }
        
        if isMSISDN {
            checkNumber(number: name)
            return
        }
        
        let a = name.split(separator: " ", maxSplits: 1)
        let first = String(a[0])
        let last = a.count == 2 ? String(a[1]) : ""
        
        if first.count > 24 {
            self.showFailedSignUpIn(title: "First name is too long".localized(), withLoader: false)
            return
        }
        
        if last.count > 24 {
            self.showFailedSignUpIn(title: "Last name is too long".localized(), withLoader: false)
            return
        }
        
        let idMe = User.getMyPin()!

        if !name.matches("^[a-zA-Z0-9 ]*$") {
            self.showFailedSignUpIn(title: "Contains prohibited characters. Only alphabetic characters are allowed.".localized(), withLoader: false)
            return
        }
        let password = passwordField.text ?? ""
        if !passwordField.isHidden {
            if password.isEmpty {
                self.showFailedSignUpIn(title: "Password can't be empty".localized(), withLoader: false)
                return
            }
            if password.count < 6 {
                self.showFailedSignUpIn(title: "Password min 6 character".localized(), withLoader: false)
                return
            }
        }
        if !CheckConnection.isConnectedToNetwork() || API.nGetCLXConnState() == 0 {
            self.showFailedSignUpIn(title: "Check your connection".localized(), withLoader: false)
            return
        }
        if KeyManagerNexilis.hasGeneratedKey() {
            KeyManagerNexilis.deleteKey()
            KeyManagerNexilis.deleteMarker()
        }
        KeyManagerNexilis.generateKey()
        KeyManagerNexilis.saveMarker()
        guard let privateKey = KeyManagerNexilis.getPrivateKey() else {
            KeyManagerNexilis.deleteKey()
            KeyManagerNexilis.deleteMarker()
            UIApplication.shared.visibleViewController?.view.makeToast("Biometric or passcode authentication required".localized(), duration: 3, position: .center)
            return
        }
        if Database.shared.openDatabase() == 0 {
            APIS.showRestartApp()
            KeyManagerNexilis.deleteKey()
            KeyManagerNexilis.deleteMarker()
            return
        }
        Nexilis.showLoader()
        DispatchQueue.global().async {
            if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChalanger()) {
                if response.isOk() {
                    let data = response.getBody(key: CoreMessage_TMessageKey.DATA, default_value: "")
                    if data.isEmpty {
                        DispatchQueue.main.async {
                            self.showFailedSignUpIn(title: "Failed to get auth, please try again".localized())
                        }
                        return
                    }
                    let md5Hex = password
                    var pk = ""
                    var sign = ""
                    let df = HMACDeviceFingerprintNexilis.generate()
                    if let dataSign = "\(data)!\(df)".data(using: .utf8) {
                        if let signature = KeyManagerNexilis.sign(data: dataSign, privateKey: privateKey) {
                            sign = signature.base64EncodedString()
                        }
                    }
                    if let publicKey = KeyManagerNexilis.getRSAX509PublicKeyBase64(privateKey: privateKey) {
                        pk = publicKey
                    }
                    if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSignUpSignInAPI(p_name: name, p_password: md5Hex, deviceFingerprint: df, publicKey: pk, signature: sign), timeout: 30 * 1000) {
                        if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "20" {
                            DispatchQueue.main.async {
                                self.showFailedSignUpIn(title: "Invalid user / Username and password does not match".localized())
                            }
                        } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                            DispatchQueue.main.async {
                                self.showFailedSignUpIn(title: "Failed, unknown user".localized())
                            }
                        } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "4u" {
                            DispatchQueue.main.async {
                                self.showFailedSignUpIn(title: "Failed, blocked user".localized())
                            }
                        } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "13" {
                            DispatchQueue.main.async {
                                self.showFailedSignUpIn(title: "Failed, This user is not registered on this device".localized())
                            }
                        } else if !response.isOk() {
                            DispatchQueue.main.async {
                                self.showFailedSignUpIn(title: "Failed".localized())
                            }
                        } else {
                            self.successSubmit(response: response, first: first, last: last)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.showFailedSignUpIn(title: "Unable to access servers. Try again later".localized())
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showFailedSignUpIn(title: "Failed to get auth, please try again".localized())
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.showFailedSignUpIn(title: "Unable to access servers. Try again later".localized())
                }
            }
        }
    }
    
    private func successSubmit(response: TMessage, first: String, last: String, email: String = "", number: String = "") {
        let sign = response.getBody(key: CoreMessage_TMessageKey.SIGN, default_value: "")
        if sign == "1" || !email.isEmpty || !number.isEmpty {
            let id = response.getBody(key: CoreMessage_TMessageKey.F_PIN, default_value: "")
            let f_pin = response.getBody(key: CoreMessage_TMessageKey.F_PIN_REAL, default_value: "")
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
                        if self.forceLogin {
                            self.navigationController?.dismiss(animated: true)
                        } else {
                            let controllers = self.navigationController?.viewControllers
                            if controllers![controllers!.count - 2] is SignInOption {
                                self.navigationController?.popToViewController(controllers![0], animated: true)
                            } else {
                                self.navigationController?.popViewController(animated: true)
                            }
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
                        if self.forceLogin {
                            self.navigationController?.dismiss(animated: true)
                        } else {
                            let controllers = self.navigationController?.viewControllers
                            if controllers![controllers!.count - 2] is SignInOption {
                                self.navigationController?.popToViewController(controllers![controllers!.count - 3], animated: true)
                            } else {
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    })
                })
            }
        } else {
            let idMe = User.getMyPin()!
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                var firstN = first
                if firstN.isEmpty {
                    if !email.isEmpty {
                        firstN = email
                    } else {
                        firstN = number
                    }
                }
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
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onRefreshWebView"), object: nil, userInfo: nil)
            DispatchQueue.main.async {
                Nexilis.hideLoader(completion: {
                    let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Successfully Sign-Up".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                    banner.show()
                    if self.forceLogin {
                        self.navigationController?.dismiss(animated: true)
                    } else {
                        let controllers = self.navigationController?.viewControllers
                        if controllers![controllers!.count - 2] is SignInOption {
                            self.navigationController?.popToViewController(controllers![controllers!.count - 3], animated: true)
                        } else {
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                })
            }
        }
    }

}
