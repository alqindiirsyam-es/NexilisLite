//
//  ProfileViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 17/09/21.
//

import UIKit
import NotificationBannerSwift
import nuSDKService

public class ProfileViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var profile: UIImageView!
    
    @IBOutlet weak var call: UIButton!
    @IBOutlet weak var video: UIButton!
    @IBOutlet weak var message: UIButton!
    @IBOutlet weak var viewUserType: UIView!
    @IBOutlet weak var imageUserType: UIImageView!
    @IBOutlet weak var qrImage: UIImageView!
    @IBOutlet weak var labelUserType: UILabel!
    @IBOutlet weak var buttonGroup: UIStackView!
    @IBOutlet weak var myViewGroup: UIView!
    @IBOutlet weak var switchPrivateAccount: UISwitch!
    @IBOutlet weak var buttonEditPass: UIButton!
    @IBOutlet weak var switchAcceptCall: UISwitch!
    @IBOutlet weak var buttonHistoryCC: UIButton!
    @IBOutlet weak var viewFriend: UIView!
    @IBOutlet weak var countFriend: UILabel!
    @IBOutlet weak var labelPrivateAccount: UILabel!
    @IBOutlet weak var labelChangePassword: UILabel!
    @IBOutlet weak var buttonEditpass: UIButton!
    @IBOutlet weak var labelAcceptCall: UILabel!
    @IBOutlet weak var buttonSaveStatus: UIButton!
    @IBOutlet weak var editTextStatus: UITextField!
    @IBOutlet weak var contStatusFriend: UIView!
    @IBOutlet weak var statusFriend: UILabel!
    
    private var imageVideoPicker : ImageVideoPicker!
    
    public enum Flag {
        case me
        case friend
        case invite
    }
    
    var user: User?
    
    public var data: String = ""
    
    public var flag: Flag = Flag.friend
    
    var name: String = ""
    
    var picture: String = ""
    
    var checkReadMessage: (() -> ())?
    
    public var isDismiss: (() -> ())?
    
    public var dismissImage: ((UIImage, String) -> ())?
    
    var fromRootViewController = false
    
    var isBNI = false
    
    var fromListFriend = false
    
    var isLoadingAddFriend = false
    
    var publicBanner = FloatingNotificationBanner()
    
    var fromAPI = false
    var timerSwitchPA = Timer()
    var timerSwitchAC = Timer()
    
    private func reload() {
        if let user = self.user {
            self.navigationController?.navigationBar.topItem?.title = "\(user.firstName) \(user.lastName)"
            self.navigationController?.navigationBar.setNeedsLayout()
            self.title = "\(user.firstName) \(user.lastName)"
            if !user.thumb.isEmpty {
                self.profile.setImage(name: user.thumb)
            }
        } else {
            getData { user in
                self.user = user
                DispatchQueue.main.async {
                    guard let user = user else {
                        return
                    }
                    if let me = User.getMyPin(), me == self.data || self.flag == Flag.me {
                        Database.shared.database?.inTransaction({ fmdb, rollback in
                            do {
                                let idMe = User.getMyPin()!
                                if let cursorCount = Database.shared.getRecords(fmdb: fmdb, query: "select COUNT(*) from BUDDY where f_pin <> '\(idMe)' and first_name NOT LIKE 'USR%' "), cursorCount.next() {
                                    let count = cursorCount.string(forColumnIndex: 0)!
                                    self.countFriend.text = count + " " + "Friends".localized()
                                    self.countFriend.font = .systemFont(ofSize: 12)
                                    self.viewFriend.layer.cornerRadius = 5.0
                                    self.viewFriend.clipsToBounds = true
                                    self.viewFriend.isHidden = false
                                    
                                    self.viewFriend.isUserInteractionEnabled = true
                                    self.viewFriend.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.friendsTapped)))
                                    cursorCount.close()
                                }
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                    }
                    if User.isOfficialRegular(official_account: user.official ?? "") || User.isOfficial(official_account: user.official ?? "") || User.isVerified(official_account: user.official ?? "") || User.isCallCenter(userType: user.userType ?? "") || User.isInternal(userType: user.userType ?? "") {
                        self.viewUserType.layer.cornerRadius = 5.0
                        self.viewUserType.clipsToBounds = true
                        self.viewUserType.isHidden = false
                        if User.isOfficialRegular(official_account: user.official ?? "") || User.isOfficial(official_account: user.official ?? "") {
                            self.imageUserType.image = UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                            self.labelUserType.text = "Official".localized()
                        } else if User.isVerified(official_account: user.official ?? "") {
                            self.imageUserType.image = UIImage(named: "ic_verified", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                            self.labelUserType.text = "Verified".localized()
                        } else if User.isCallCenter(userType: user.userType ?? "") {
                            let dataCategory = CategoryCC.getDataFromServiceId(service_id: user.ex_offmp!)
                            self.imageUserType.image = UIImage(named: "pb_call_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
//                            if dataCategory != nil {
//                                self.labelUserType.text = "Call Center (\(dataCategory!.service_name))".localized()
//                            } else {
                                self.labelUserType.text = "Call Center".localized()
//                            }
//                            self.buttonHistoryCC.isHidden = true
                        }
                    }
                    self.navigationController?.navigationBar.topItem?.title = "\(user.firstName) \(user.lastName)"
                    self.navigationController?.navigationBar.setNeedsLayout()
                    self.title = "\(user.firstName) \(user.lastName)"
                    if !user.thumb.isEmpty {
                        self.profile.setImage(name: user.thumb)
                    }
                }
            }
        }
    }
    
    private func getData(completion: @escaping (User?) -> ()) {
        do {
            DispatchQueue.global().async {
                var r: User?
                r = User.getData(pin: self.data)
                Database.shared.database?.inTransaction({ fmdb, rollback in
                    do {
                        let idMe = User.getMyPin()!
                        if let cursorCount = Database.shared.getRecords(fmdb: fmdb, query: "select COUNT(*) from BUDDY where f_pin <> '\(idMe)' and first_name NOT LIKE 'USR%' "), cursorCount.next() {
                            DispatchQueue.main.async {
                                self.countFriend.text = cursorCount.string(forColumnIndex: 0) ?? "" + " " + "Friends".localized()
                            }
                            cursorCount.close()
                        }
                    } catch {
                        rollback.pointee = true
                        print("Access database error: \(error.localizedDescription)")
                    }
                })
                completion(r)
            }
        } catch {
            
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            self.checkReadMessage?()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
//        if navigationController?.navigationBar.backgroundColor != .clear || self.traitCollection.userInterfaceStyle == .dark {
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            navigationController?.navigationBar.tintColor = .white
            navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
//        } else {
//            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
//            navigationController?.navigationBar.tintColor = .black
//            navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .normal)
//        }
        if fromListFriend {
            if let me = User.getMyPin(), me == self.data || self.flag == Flag.me {
                Database.shared.database?.inTransaction({ fmdb, rollback in
                    let idMe = User.getMyPin()!
                    if let cursorCount = Database.shared.getRecords(fmdb: fmdb, query: "select COUNT(*) from BUDDY where f_pin <> '\(idMe)' and first_name NOT LIKE 'USR%'"), cursorCount.next() {
                        let count = cursorCount.string(forColumnIndex: 0)!
                        self.countFriend.text = count + " " + "Friends".localized()
                        cursorCount.close()
                    }
                })
            }
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        navigationController?.navigationBar.titleTextAttributes = nil
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        if let me = User.getMyPin(), me == data || flag == Flag.me || flag == Flag.friend {
            reload()
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        pullBuddy()
        
        profile.circle()
        profile.contentMode = .scaleAspectFill
        
        profile.isUserInteractionEnabled = true
        profile.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileTapped)))
        
        let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0), NSAttributedString.Key.foregroundColor: UIColor.white]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
        navBarAppearance.titleTextAttributes = attributes
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        if fromAPI {
            let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(self.didTapExit))
            self.navigationItem.leftBarButtonItem = backButton
        }
        
//        self.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .black : .white
        
        if fromRootViewController {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapExit(sender:)))
        }
        let myData = User.getData(pin: self.data)
        labelPrivateAccount.text = "Private Account Mode".localized()
        labelChangePassword.text = "Change Password".localized()
        labelAcceptCall.text = "Accept Call".localized()
        buttonHistoryCC.setAttributedTitle(NSAttributedString(string: "Call Center History".localized(), attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor : self.traitCollection.userInterfaceStyle == .dark ? UIColor.blackDarkMode : UIColor.white]), for: .normal)
//        buttonQRCode.setAttributedTitle(NSAttributedString(string: "Show QR Code".localized(), attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor : self.traitCollection.userInterfaceStyle == .dark ? UIColor.blackDarkMode : UIColor.white]), for: .normal)
        navigationController?.navigationBar.topItem?.backButtonTitle = "Back".localized()
        
        switchPrivateAccount.onTintColor = .mainColor
        switchAcceptCall.onTintColor = .mainColor
        buttonEditpass.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        buttonHistoryCC.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .secondaryColor : .black
//        buttonQRCode.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .secondaryColor : .black
        let qrTapGesture = UITapGestureRecognizer(target: self, action: #selector(showQR(sender:)))
        qrImage.isUserInteractionEnabled = true
        qrImage.contentMode = .scaleAspectFit
        qrImage.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .secondaryColor : .black
        qrImage.translatesAutoresizingMaskIntoConstraints = false
        qrImage.addGestureRecognizer(qrTapGesture)
        
        if let me = User.getMyPin(), me == data || flag == Flag.me {
            contStatusFriend.isHidden = true
            buttonGroup.removeFromSuperview()
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit".localized(), style: .plain, target: self, action: #selector(didTapEdit(sender:)))
            imageVideoPicker = ImageVideoPicker(presentationController: self, delegate: self)
            buttonEditPass.addTarget(self, action: #selector(editPassword(sender:)), for: .touchUpInside)
            buttonHistoryCC.addTarget(self, action: #selector(historyCC(sender:)), for: .touchUpInside)
//            buttonQRCode.addTarget(self, action: #selector(showQR(sender:)), for: .touchUpInside)
            
            if myData?.privacy_flag == "1" {
                switchPrivateAccount.setOn(true, animated: false)
            }
            if myData?.offline_mode == "1" {
                switchAcceptCall.setOn(false, animated: false)
            }
            switchPrivateAccount.addTarget(self, action: #selector(privateAccountSwitch), for: .valueChanged)
            switchAcceptCall.addTarget(self, action: #selector(acceptCallSwitch), for: .valueChanged)
            editTextStatus.placeholder = "Write a status".localized()
            editTextStatus.text = myData?.status
            editTextStatus.delegate = self
            buttonSaveStatus.isHidden = true
            
            buttonSaveStatus.addTarget(self, action: #selector(saveStatus(sender:)), for: .touchUpInside)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            tapGesture.cancelsTouchesInView = false
            myViewGroup.addGestureRecognizer(tapGesture)
        } else if flag == Flag.invite {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd(sender:)))
            call.isEnabled = false
            video.isEnabled = false
            message.isEnabled = false
            myViewGroup.removeFromSuperview()
            buttonGroup.removeFromSuperview()
            title = name
            profile.setImage(name: picture)
        } else if flag == Flag.friend {
            statusFriend.text = myData?.status
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "person.crop.circle.badge.xmark"), style: .plain, target: self, action: #selector(didTapUnfriend(sender:)))
            if !isBNI {
                call.addTarget(self, action: #selector(call(sender:)), for: .touchUpInside)
                video.addTarget(self, action: #selector(video(sender:)), for: .touchUpInside)
                message.addTarget(self, action: #selector(chat(sender:)), for: .touchUpInside)
            } else {
                call.isEnabled = false
                video.isEnabled = false
                message.isEnabled = false
                buttonGroup.removeFromSuperview()
            }
            myViewGroup.removeFromSuperview()
        }
    }
    
    @objc func dismissKeyboard() {
        if editTextStatus.isFirstResponder {
            editTextStatus.resignFirstResponder()
        }
    }
    
    public func textFieldDidChangeSelection(_ textField: UITextField) {
        if let text = textField.text {
            if text == user?.status {
                buttonSaveStatus.isHidden = true
            } else {
                buttonSaveStatus.isHidden = false
            }
        }
    }
    
    @objc func saveStatus(sender: Any) {
        dismissKeyboard()
        Nexilis.showLoader()
        let text = editTextStatus.text ?? ""
        let pin = self.data
        DispatchQueue.global().async {
            if let resp = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChangePersonInfoQuote(quote: text)), resp.isOk() {
                Database.shared.database?.inTransaction({ fmdb, rollback in
                    do {
                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: ["quote": text], _where: "f_pin = '\(pin)'")
                    } catch {
                        rollback.pointee = true
                        print("Access database error: \(error.localizedDescription)")
                    }
                })
                DispatchQueue.main.async {
                    Nexilis.hideLoader {
                        self.buttonSaveStatus.isHidden = true
                        self.user?.status = self.editTextStatus.text!
                        self.editTextStatus.text = self.editTextStatus.text!
                        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                        imageView.tintColor = .white
                        self.publicBanner.dismiss()
                        self.publicBanner = FloatingNotificationBanner(title: "Successfully changed status".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                        self.publicBanner.show()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    Nexilis.hideLoader {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            }
        }
    }
    
    @objc func acceptCallSwitch(mySwitch: UISwitch) {
        timerSwitchAC.invalidate()
        timerSwitchAC = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [self] _ in
            let value = mySwitch.isOn
            if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                publicBanner.dismiss()
                publicBanner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                publicBanner.show()
                self.switchPrivateAccount.setOn(!value, animated: true)
                return
            }
            DispatchQueue.global().async {
                let tMessage = CoreMessage_TMessageBank.getChangePersonInfo_New(p_f_pin: self.data)
                tMessage.mBodies[CoreMessage_TMessageKey.OFFLINE_MODE] = value ? "0" : "1"
                if let resp = Nexilis.writeAndWait(message: tMessage) {
                    if resp.isOk() {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: [
                                    "offline_mode" : value ? "0" : "1"
                                ], _where: "f_pin = '\(self.data)'")
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                        DispatchQueue.main.async { [self] in
                            let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                            imageView.tintColor = .white
                            publicBanner.dismiss()
                            publicBanner = FloatingNotificationBanner(title: "Successfully changed".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                            publicBanner.show()
                        }
                    } else {
                        DispatchQueue.main.async { [self] in
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            publicBanner.dismiss()
                            publicBanner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            publicBanner.show()
                            self.switchPrivateAccount.setOn(!value, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    @objc func privateAccountSwitch(mySwitch: UISwitch) {
        timerSwitchPA.invalidate()
        timerSwitchPA = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [self] _ in
            let value = mySwitch.isOn
            if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                publicBanner.dismiss()
                publicBanner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                publicBanner.show()
                self.switchPrivateAccount.setOn(!value, animated: true)
                return
            }
            DispatchQueue.global().async {
                let tMessage = CoreMessage_TMessageBank.getChangePersonInfo_New(p_f_pin: self.data)
                tMessage.mBodies[CoreMessage_TMessageKey.PRIVACY_FLAG] = value ? "1" : "0"
                if let resp = Nexilis.writeAndWait(message: tMessage) {
                    if resp.isOk() {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: [
                                    "privacy_flag" : value ? "1" : "0"
                                ], _where: "f_pin = '\(self.data)'")
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                        DispatchQueue.main.async { [self] in
                            let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                            imageView.tintColor = .white
                            publicBanner.dismiss()
                            publicBanner = FloatingNotificationBanner(title: "Successfully changed".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                            publicBanner.show()
                        }
                    } else {
                        DispatchQueue.main.async { [self] in
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            publicBanner.dismiss()
                            publicBanner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            publicBanner.show()
                            self.switchPrivateAccount.setOn(!value, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    @objc func editPassword(sender: Any) {
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "changePWD") as! ChangePasswordViewController
        navigationController?.show(controller, sender: nil)
    }
    
    @objc func historyCC(sender: Any) {
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "myHistoryCC") as! HistoryCCViewController
        if user?.userType == "24" {
            controller.isOfficer = true
        } else {
            controller.isOfficer = false
        }
        navigationController?.show(controller, sender: nil)
    }
    
    @objc func showQR(sender: Any){
        // TODO: Show Controller
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "qrProfile") as! QRProfileController
        controller.fPin = self.data
        navigationController?.show(controller, sender: nil)
    }
    
    @objc func call(sender: Any) {
        if !Nexilis.checkingAccess(key: "audio_call") {
            self.view.makeToast("Feature disabled..".localized(), duration: 3)
            return
        }
        let myData = User.getData(pin: self.data)
        if myData?.ex_block == "1" || myData?.ex_block == "-1" {
            var title = "You blocked this user".localized()
            if myData?.ex_block == "-1" {
                title = "You have been blocked by this user".localized()
            }
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            publicBanner.dismiss()
            publicBanner = FloatingNotificationBanner(title: title, subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            publicBanner.show()
            return
        }
        if !CheckConnection.isConnectedToNetwork() {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            publicBanner.dismiss()
            publicBanner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            publicBanner.show()
            return
        }
        let controller = QmeraAudioViewController()
        controller.user = user
        controller.isOutgoing = true
        controller.modalPresentationStyle = .overCurrentContext
        present(controller, animated: true, completion: nil)
    }
    
    @objc func video(sender: Any) {
        if !Nexilis.checkingAccess(key: "video_call") {
            self.view.makeToast("Feature disabled..".localized(), duration: 3)
            return
        }
        let myData = User.getData(pin: self.data)
        if myData?.ex_block == "1" || myData?.ex_block == "-1" {
            var title = "You blocked this user".localized()
            if myData?.ex_block == "-1" {
                title = "You have been blocked by this user".localized()
            }
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            publicBanner.dismiss()
            publicBanner = FloatingNotificationBanner(title: title, subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            publicBanner.show()
            return
        }
        if !CheckConnection.isConnectedToNetwork() {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            publicBanner.dismiss()
            publicBanner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            publicBanner.show()
            return
        }
        if let user = user {
            let videoVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "videoVCQmera") as! QmeraVideoViewController
            videoVC.fPin = user.pin
            self.show(videoVC, sender: nil)
        }
    }
    
    @objc func chat(sender: Any) {
        if let _ = previousViewController as? EditorPersonal {
            navigationController?.popViewController(animated: true)
            return
        }
        if let user = self.user {
            let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
            editorPersonalVC.hidesBottomBarWhenPushed = true
            editorPersonalVC.unique_l_pin = user.pin
            navigationController?.show(editorPersonalVC, sender: nil)
        }
    }
    
    private func addFriend(completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            guard !self.data.isEmpty else {
                completion(false)
                return
            }
            var dataMessage = CoreMessage_TMessageBank.getAddFriendQRCode(fpin: self.data)
            if Nexilis.checkingAccess(key: "friend_request_approval"){
                dataMessage = CoreMessage_TMessageBank.getAddFriendRequest(fPin: self.data)
            }
            if let response = Nexilis.writeAndWait(message: dataMessage), response.isOk() {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    private func unFriend(completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            guard !self.data.isEmpty else {
                completion(false)
                return
            }
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.removeFriend(lpin: self.user!.pin)), response.isOk() {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func didTapProfile() {
        if let me = User.getMyPin(), me == data || flag == Flag.me {
            if let userImage = user?.thumb {
                if !userImage.isEmpty {
                    let firstAlert = LibAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    firstAlert.addAction(UIAlertAction(title: "Change Profile Picture".localized(), style: .default, handler: { action in
                        let alert = LibAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                        alert.addAction(UIAlertAction(title: "Take Photo".localized(), style: .default, handler: { action in
                            self.imageVideoPicker.present(source: .imageCamera)
                        }))
                        alert.addAction(UIAlertAction(title: "Choose Photo".localized(), style: .default, handler: { action in
                            self.imageVideoPicker.present(source: .imageAlbum)
                        }))
                        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { action in
                            
                        }))
                        self.navigationController?.present(alert, animated: true)
                    }))
                    firstAlert.addAction(UIAlertAction(title: "Remove Profile Picture".localized(), style: .default, handler: { action in
                        if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChangePersonImage(thumb_id: "")), response.isOk() {
                            guard let me = User.getMyPin() else {
                                return
                            }
                            Database.shared.database?.inTransaction({ fmdb, rollback in
                                do {
                                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: ["image_id": ""], _where: "f_pin = '\(me)'")
                                } catch {
                                    rollback.pointee = true
                                    print("Access database error: \(error.localizedDescription)")
                                }
                            })
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateFifthTab"), object: nil, userInfo: nil)
                            
                            DispatchQueue.main.async { [self] in
                                self.profile.image = UIImage(systemName: "person.circle.fill")!
                                self.profile.backgroundColor = .white
                                self.user?.thumb = ""
                                let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                imageView.tintColor = .white
                                publicBanner.dismiss()
                                publicBanner = FloatingNotificationBanner(title: "Successfully removed profile picture".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                publicBanner.show()
                                self.dismissImage?(UIImage(systemName: "person.circle.fill")!, "")
                            }
                        }
                    }))
                    firstAlert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
                    self.navigationController?.present(firstAlert, animated: true)
                } else {
                    let alert = LibAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    alert.addAction(UIAlertAction(title: "Take Photo".localized(), style: .default, handler: { action in
                        self.imageVideoPicker.present(source: .imageCamera)
                    }))
                    alert.addAction(UIAlertAction(title: "Choose Photo".localized(), style: .default, handler: { action in
                        self.imageVideoPicker.present(source: .imageAlbum)
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { action in
                        
                    }))
                    self.navigationController?.present(alert, animated: true)
                }
            }
        } else {
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(self.user!.thumb)
                if FileManager.default.fileExists(atPath: imageURL.path) {
                    let image    = UIImage(contentsOfFile: imageURL.path)
                    let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
                    previewImageVC.image = image
                    previewImageVC.isHiddenTextField = true
                    previewImageVC.modalPresentationStyle = .custom
                    previewImageVC.modalTransitionStyle  = .crossDissolve
                    self.present(previewImageVC, animated: true, completion: nil)
                } else if FileEncryption.shared.isSecureExists(filename: self.user!.thumb) {
                    do {
                        if var data = try FileEncryption.shared.readSecure(filename: self.user!.thumb) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                            if dataDecrypt != nil {
                                data = dataDecrypt!
                            }
                            let image = UIImage(data: data)
                            let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
                            previewImageVC.image = image
                            previewImageVC.isHiddenTextField = true
                            previewImageVC.modalPresentationStyle = .custom
                            previewImageVC.modalTransitionStyle  = .crossDissolve
                            self.present(previewImageVC, animated: true, completion: nil)
                        }
                    }
                    catch {
                        print("Error reading secure file")
                    }
                }
            }
        }
    }
    
    @objc func didTapAdd(sender: Any) {
        if isLoadingAddFriend {
            return
        }
        Nexilis.showLoader()
        isLoadingAddFriend = true
        addFriend { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                Nexilis.hideLoader { [self] in
                    if result {
                        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                        imageView.tintColor = .white
                        publicBanner.dismiss()
                        publicBanner = FloatingNotificationBanner(title: Nexilis.checkingAccess(key: "friend_request_approval") ? "Friend request has been sent".localized() : "Successfully add friend".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                        publicBanner.show()
                        self.isDismiss?()
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        publicBanner.dismiss()
                        publicBanner = FloatingNotificationBanner(title: "Server busy, please try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        publicBanner.show()
                        self.isLoadingAddFriend = false
                    }
                }
            })
        }
    }
    
    @objc func didTapUnfriend(sender: Any) {
        if call != nil {
            call.isEnabled = false
            video.isEnabled = false
            message.isEnabled = false
        }
        Nexilis.shared.stateUnfriend = self.data
        let alert = LibAlertController(title: "", message: "Are you sure to unfriend".localized() + " \(self.user!.fullName)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: UIAlertAction.Style.default, handler: {(_) in
            if self.call != nil {
                self.call.isEnabled = true
                self.video.isEnabled = true
                self.message.isEnabled = true
            }
            Nexilis.shared.stateUnfriend = ""
        } ))
        alert.addAction(UIAlertAction(title: "Delete".localized(), style: .destructive, handler: {(_) in
            Nexilis.showLoader()
            self.unFriend { result in
                DispatchQueue.main.async { [self] in
                    if result {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select * from BUDDY where f_pin = '\(self.data)'"), cursor.next() {
                                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "BUDDY", _where: "f_pin = '\(self.data)'")
                                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "l_pin='\(self.data)'")
                                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "(f_pin='\(self.data)' or l_pin='\(self.data)') and message_scope_id='3'")
                                    cursor.close()
                                }
                                Nexilis.hideLoader(completion: {
                                    if self.previousViewController is GroupDetailViewController || self.isBNI {
                                        self.isDismiss?()
                                        self.navigationController?.popViewController(animated: true)
                                    } else {
                                        if let editor = self.previousViewController as? EditorPersonal {
                                            editor.afterUnfriend()
                                        } else if let editor = self.previousViewController as? EditorGroup {
                                            editor.afterUnfriend()
                                        }
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                                        self.navigationController?.popToRootViewController(animated: true)
                                    }
                                    Nexilis.shared.stateUnfriend = ""
                                })
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                    } else {
                        if self.call != nil {
                            self.call.isEnabled = true
                            self.video.isEnabled = true
                            self.message.isEnabled = true
                        }
                        Nexilis.shared.stateUnfriend = ""
                        Nexilis.hideLoader(completion: {})
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        publicBanner.dismiss()
                        publicBanner = FloatingNotificationBanner(title: "Server busy, please try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        publicBanner.show()
                    }
                }
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func didTapExit(sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapEdit(sender: Any) {
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "changeNameView") as! ChangeNameTableViewController
        controller.data = data
        controller.isDismiss = {
            self.getData { user in
                self.user = user
                DispatchQueue.main.async {
                    guard let user = user else {
                        return
                    }
                    self.title = "\(user.firstName) \(user.lastName)"
                    if !user.thumb.isEmpty {
                        self.profile.setImage(name: user.thumb)
                    }
                }
            }
            let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
            imageView.tintColor = .white
            self.publicBanner.dismiss()
            self.publicBanner = FloatingNotificationBanner(title: "Successfully changed name".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
            self.publicBanner.show()
        }
        navigationItem.backButtonTitle = ""
        navigationController?.show(controller, sender: nil)
    }
    
    @objc func profileTapped() {
        didTapProfile()
    }
    
    @objc func friendsTapped() {
        if let me = User.getMyPin(), me == data || flag == Flag.me {
            let controller = QmeraCallContactViewController()
            controller.isInviteCC = true
            controller.listFriends = true
            show(controller, sender: nil)
            fromListFriend = true
        }
    }
    
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 {
            if let me = User.getMyPin(), me == data || flag == Flag.me {
                return 220
            }
            return 56
        }

        return 200
    }
    
    private func pullBuddy() {
        if let me = User.getMyPin() {
            DispatchQueue.global().async {
                let _ = Nexilis.write(message: CoreMessage_TMessageBank.getBatchBuddiesInfos(p_f_pin: me, last_update: 0))
            }
        }
    }
}

extension ProfileViewController: ImageVideoPickerDelegate {
    
    public func didSelect(imagevideo: Any?) {
        if let info = imagevideo as? [UIImagePickerController.InfoKey: Any], let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            guard let me = User.getMyPin() else {
                return
            }
            Nexilis.showLoader()
            DispatchQueue.global().async {
                let resize = image.resize(target: CGSize(width: 800, height: 600))
                let documentDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let data = resize.jpegData(compressionQuality: 0.8)
                guard let data = data else { return }
                let fileDir = documentDir.appendingPathComponent("THUMB_\(me)\(Date().currentTimeMillis().toHex()).jpg")
                if !FileManager.default.fileExists(atPath: fileDir.path) {
                    try! data.write(to: fileDir)
                    Network().uploadHTTP(name: fileDir.lastPathComponent) { result, progress in
                        guard result else {
                            DispatchQueue.main.async {
                                Nexilis.hideLoader(completion: { [self] in
                                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                    imageView.tintColor = .white
                                    publicBanner.dismiss()
                                    publicBanner = FloatingNotificationBanner(title: "Can't change profile picture, try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                                    publicBanner.show()
                                    self.dismissImage?(image, fileDir.lastPathComponent)
                                })
                            }
                            return
                        }
                        guard progress == 100 else {
                            return
                        }
                        do {
                            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                            let fileURL = documentsDirectory.appendingPathComponent(fileDir.lastPathComponent)
                            try FileEncryption.shared.writeSecure(filename: fileDir.lastPathComponent, data: Data(contentsOf: fileURL))
                            try FileManager.default.removeItem(atPath: fileURL.path)
                        } catch {
                            
                        }
                        if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChangePersonImage(thumb_id: fileDir.lastPathComponent)), response.isOk() {
                            Database.shared.database?.inTransaction({ fmdb, rollback in
                                do {
                                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: ["image_id": fileDir.lastPathComponent], _where: "f_pin = '\(me)'")
                                } catch {
                                    rollback.pointee = true
                                    print("Access database error: \(error.localizedDescription)")
                                }
                            })
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateFifthTab"), object: nil, userInfo: nil)
                            
                            DispatchQueue.main.async {
                                Nexilis.hideLoader(completion: { [self] in
                                    self.profile.image = image
                                    let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                    self.user?.thumb = fileDir.lastPathComponent
                                    imageView.tintColor = .white
                                    publicBanner.dismiss()
                                    publicBanner = FloatingNotificationBanner(title: "Successfully changed profile picture".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                    publicBanner.show()
                                    self.dismissImage?(image, fileDir.lastPathComponent)
                                })
                            }
                        } else {
                            Nexilis.hideLoader(completion: {})
                        }
                    }
                } else {
                    Nexilis.hideLoader(completion: {})
                }
            }
        }
    }
    
}

//if auto {
//    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
//        let objectTapAuto = ObjectGesture()
//        objectTapAuto.image_id = imageChat
//        self.contentMessageTapped(objectTap)
//    })
//}
