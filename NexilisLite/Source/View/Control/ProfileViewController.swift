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
    /// The pieces of the redrawn profile that are changed after it is built.
    var profileAvatar: UIImageView?
    var profileStatusLabel: UILabel?
    var profileNameLabel: UILabel?
    var profileBadge: UIImageView?
    var profileCard: UIView?
    var audioTile: UIControl?
    var videoTile: UIControl?
    var myFriendCount: UILabel?
    var myStatusRow: ProfileCardRow?

    /// Shows the mark that says what kind of account this is, or nothing when it is an ordinary
    /// one. Fed from the same place that used to fill the old coloured chip.
    func showUserBadge(_ image: UIImage?) {
        profileBadge?.image = image
        profileBadge?.isHidden = image == nil
    }
    var friendshipTile: UIControl?
    /// True once the new layout is in place, so the storyboard's static rows stay out of the way.
    var usesNewProfileLayout = false

    /// The picture arrives after the screen is built, and from several places. Both views that
    /// show it are filled here so the redrawn profile cannot be left with an empty circle.
    func setProfilePicture(named name: String) {
        profile?.setImage(name: name)
        profileAvatar?.setImage(name: name)
    }

    func setProfilePicture(_ image: UIImage) {
        profile?.image = image
        profileAvatar?.image = image
    }

    /// A shadow colour is a CGColor and does not follow the theme by itself, so the haloes are
    /// set again when it changes.
    public override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        guard traitCollection.userInterfaceStyle != previous?.userInterfaceStyle else {
            return
        }
        if let label = profileNameLabel {
            ProfileCardStyle.halo(label)
        }
        if let label = profileStatusLabel {
            ProfileCardStyle.halo(label)
        }
    }

    /// Where the person's name belongs.
    ///
    /// Fix: the name was written into the navigation bar, and the bar is where "Profile Info" goes
    /// now - so the buddy record arriving a moment after the screen was built put the name back
    /// over the top of it. On the redrawn profile the name is a line under the picture; the bar
    /// keeps its own words.
    func showName(_ text: String) {
        name = text
        profileNameLabel?.text = text
        guard !usesNewProfileLayout else {
            return
        }
        navigationController?.navigationBar.topItem?.title = text
        navigationController?.navigationBar.setNeedsLayout()
        title = text
    }

    /// Same for the status, which is read from the buddy record rather than passed in.
    func setProfileStatus(_ text: String?) {
        statusFriend?.text = text
        profileStatusLabel?.text = text ?? ""
    }
    
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
            self.showName("\(user.firstName) \(user.lastName)")
            if !user.thumb.isEmpty {
                self.setProfilePicture(named: user.thumb)
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
                                    self.myFriendCount?.text = count + " " + "Friends".localized()
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
                            self.showUserBadge(self.imageUserType.image)
                            self.labelUserType.text = "Official".localized()
                        } else if User.isVerified(official_account: user.official ?? "") {
                            self.imageUserType.image = UIImage(named: "ic_verified", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                            self.showUserBadge(self.imageUserType.image)
                            self.labelUserType.text = "Verified".localized()
                        } else if User.isInternal(userType: user.userType ?? "") {
                            // The outer test already allowed an internal account through, but no
                            // mark was ever chosen for it - so it reached here and came out blank.
                            self.imageUserType.image = UIImage(named: "ic_internal", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                            self.showUserBadge(self.imageUserType.image)
                            self.labelUserType.text = "Internal".localized()
                        } else if User.isCallCenter(userType: user.userType ?? "") {
                            let dataCategory = CategoryCC.getDataFromServiceId(service_id: user.ex_offmp!)
                            self.imageUserType.image = UIImage(named: "pb_call_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                            self.showUserBadge(self.imageUserType.image)
//                            if dataCategory != nil {
//                                self.labelUserType.text = "Call Center (\(dataCategory!.service_name))".localized()
//                            } else {
                                self.labelUserType.text = "Call Center".localized()
//                            }
//                            self.buttonHistoryCC.isHidden = true
                        }
                    }
                    self.showName("\(user.firstName) \(user.lastName)")
                    if !user.thumb.isEmpty {
                        self.setProfilePicture(named: user.thumb)
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
        navigationController?.navigationBar.topItem?.backButtonTitle = ""
        
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

            // Editing the name has moved beside the name itself, so the corner of the bar is left
            // empty here as it is on the other profiles.
            navigationItem.rightBarButtonItem = nil
            title = "Profile".localized()
            flag = .me
            usesNewProfileLayout = true
            installProfileLayout()
            showName("\(myData?.firstName ?? "") \(myData?.lastName ?? "")".trimmingCharacters(in: .whitespaces))
            setProfileStatus(myData?.status)
        } else if flag == Flag.invite {
            navigationItem.rightBarButtonItem = nil
            call.isEnabled = false
            video.isEnabled = false
            message.isEnabled = false
            myViewGroup.removeFromSuperview()
            buttonGroup.removeFromSuperview()
            // Not a friend yet, so not "Friend Info".
            title = "Profile Info".localized()
            setProfilePicture(named: picture)
            usesNewProfileLayout = true
            installProfileLayout()
        } else if flag == Flag.friend {
            setProfileStatus(myData?.status)
            // Unfriending has moved into the row of three below the name, so the corner of the bar
            // is left empty - the reference has nothing there either.
            navigationItem.rightBarButtonItem = nil
            title = "Friend Info".localized()
            usesNewProfileLayout = true
            installProfileLayout()
            // Again now the label exists: the status was read a moment ago, before there was
            // anywhere to put it.
            setProfileStatus(myData?.status)
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
        if APIS.blockedByCallInProgress() {
            return
        }
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
        if APIS.blockedByCallInProgress() {
            return
        }
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
                                self.setProfilePicture(UIImage(systemName: "person.circle.fill")!)
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
            let imageUser = self.user != nil ? self.user!.thumb : self.picture
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(imageUser)
                if FileManager.default.fileExists(atPath: imageURL.path) {
                    do {
                        APIS.openImageNexilis(imageView: self.profile, data: try Data(contentsOf: imageURL))
                    } catch {
                        
                    }
                } else if FileEncryption.shared.isSecureExists(filename: imageUser) {
                    do {
                        if var data = try FileEncryption.shared.readSecure(filename: imageUser) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                            if dataDecrypt != nil {
                                data = dataDecrypt!
                            }
                            APIS.openImageNexilis(imageView: self.profile, data: data)
                        }
                    }
                    catch {
                        print("Error reading secure file")
                    }
                }
            }
        }
    }
    
    /// Called when the friendship changes, so the screen matches what is now true.
    func refreshForFriendshipChange() {
        title = (flag == .friend ? "Friend Info" : "Profile Info").localized()
        refreshFriendshipButton()
        applyStrangerLimits()
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
                        self.setProfilePicture(named: user.thumb)
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
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return usesNewProfileLayout ? 0 : super.numberOfSections(in: tableView)
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usesNewProfileLayout ? 0 : super.tableView(tableView, numberOfRowsInSection: section)
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
                                    self.setProfilePicture(image)
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

// MARK: - The person's profile, laid out afresh

extension ProfileViewController {

    /// Whether this screen is showing somebody else rather than the reader's own account.
    var showsSomebodyElse: Bool {
        return flag != .me
    }

    /// Builds the profile the way the reference has it: the picture, the name, the status, a row
    /// of three things to do, and the conversation's media and starred messages beneath.
    ///
    /// Drawn here rather than in the storyboard, and put in the table's background view, which
    /// fills the screen and does not scroll with rows there are none of. The storyboard's own
    /// static cells are left where they are - they still serve the reader's own profile - and are
    /// simply not asked for.
    func installProfileLayout() {
        let page = UIScrollView()
        page.alwaysBounceVertical = true
        // Fix: a colour was set here, but the screen behind is a grouped table and its own grey
        // was what showed. The conversation does not pick a colour either - it calls the shared
        // background, which is the app's own artwork or its fallback pair. The same call, on the
        // table itself so nothing of the system's shows through.
        page.backgroundColor = .clear

        let column = UIStackView()
        column.axis = .vertical
        column.alignment = .fill
        column.spacing = 0
        column.translatesAutoresizingMaskIntoConstraints = false
        page.addSubview(column)
        NSLayoutConstraint.activate([
            column.topAnchor.constraint(equalTo: page.contentLayoutGuide.topAnchor, constant: 24),
            column.leadingAnchor.constraint(equalTo: page.contentLayoutGuide.leadingAnchor),
            column.trailingAnchor.constraint(equalTo: page.contentLayoutGuide.trailingAnchor),
            column.bottomAnchor.constraint(equalTo: page.contentLayoutGuide.bottomAnchor, constant: -24),
            column.widthAnchor.constraint(equalTo: page.frameLayoutGuide.widthAnchor)
        ])

        // The picture, at the size the reference draws it.
        let avatar = UIImageView()
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 60
        avatar.backgroundColor = .tertiarySystemFill
        avatar.image = profile?.image
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileTapped)))
        avatar.translatesAutoresizingMaskIntoConstraints = false
        profileAvatar = avatar
        column.addArrangedSubview(centred(avatar, size: 120))
        column.setCustomSpacing(14, after: column.arrangedSubviews.last!)

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .boldSystemFont(ofSize: 22)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2
        ProfileCardStyle.halo(nameLabel)
        profileNameLabel = nameLabel

        // Official, verified, call centre - kept, but as the mark alone in front of the name. The
        // old screen spelled it out in a coloured chip; the name is what the reader came for.
        let badge = UIImageView()
        badge.contentMode = .scaleAspectFit
        badge.isHidden = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.widthAnchor.constraint(equalToConstant: 20).isActive = true
        badge.heightAnchor.constraint(equalToConstant: 20).isActive = true
        badge.setContentHuggingPriority(.required, for: .horizontal)
        profileBadge = badge

        // The QR sits with the name because that is what it is - this person's identity, not one
        // more thing to do with them. It also keeps the row of three below intact.
        //
        // Fix: the QR lived in a storyboard cell, and those are no longer shown - so on the
        // redrawn profile it could not be reached at all.
        let qr = UIButton(type: .system)
        var qrStyle = UIButton.Configuration.plain()
        qrStyle.image = UIImage(systemName: "qrcode", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular))
        qrStyle.contentInsets = .zero
        qr.configuration = qrStyle
        qr.tintColor = .secondaryLabel
        qr.addTarget(self, action: #selector(showQR(sender:)), for: .touchUpInside)
        qr.translatesAutoresizingMaskIntoConstraints = false
        qr.widthAnchor.constraint(equalToConstant: 28).isActive = true
        qr.heightAnchor.constraint(equalToConstant: 28).isActive = true
        qr.setContentHuggingPriority(.required, for: .horizontal)

        // Editing the name lives beside it rather than in the corner of the bar: it belongs to the
        // name, not to the screen, and the corner is where the reference leaves empty.
        let pencil = UIButton(type: .system)
        var pencilStyle = UIButton.Configuration.plain()
        pencilStyle.image = UIImage(systemName: "pencil", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular))
        pencilStyle.contentInsets = .zero
        pencil.configuration = pencilStyle
        pencil.tintColor = .secondaryLabel
        pencil.addTarget(self, action: #selector(didTapEdit(sender:)), for: .touchUpInside)
        pencil.translatesAutoresizingMaskIntoConstraints = false
        pencil.widthAnchor.constraint(equalToConstant: 28).isActive = true
        pencil.heightAnchor.constraint(equalToConstant: 28).isActive = true
        pencil.setContentHuggingPriority(.required, for: .horizontal)
        pencil.isHidden = flag != .me

        let nameRow = UIStackView(arrangedSubviews: [badge, nameLabel, qr, pencil])
        nameRow.axis = .horizontal
        nameRow.alignment = .center
        nameRow.spacing = 6
        column.addArrangedSubview(padded(centredRow(nameRow)))
        column.setCustomSpacing(4, after: column.arrangedSubviews.last!)

        // Empty when there is nothing to say - the row simply takes no room.
        let statusLabel = UILabel()
        statusLabel.text = user?.status ?? ""
        statusLabel.font = .systemFont(ofSize: 15)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        ProfileCardStyle.halo(statusLabel)
        profileStatusLabel = statusLabel
        column.addArrangedSubview(padded(statusLabel))
        column.setCustomSpacing(22, after: column.arrangedSubviews.last!)

        if flag == .me {
            let friends = UILabel()
            friends.font = .systemFont(ofSize: 15)
            friends.textColor = .secondaryLabel
            friends.textAlignment = .center
            friends.isUserInteractionEnabled = true
            friends.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(friendsTapped)))
            ProfileCardStyle.halo(friends)
            myFriendCount = friends
            column.addArrangedSubview(padded(friends))
            column.setCustomSpacing(24, after: column.arrangedSubviews.last!)
        } else {
            column.addArrangedSubview(buildActionRow())
            column.setCustomSpacing(24, after: column.arrangedSubviews.last!)
        }

        let card = flag == .me ? buildMyCard() : buildLinksCard()
        profileCard = card
        column.addArrangedSubview(card)

        // A plain view carries the background, with the scrolling content on top of it.
        //
        // Fix: the shared background was asked to paint the table itself, and it works by putting
        // an image view inside whatever it is given - inside a table that lands in front of the
        // background view and hid the whole screen. It is given a view of its own here, and the
        // content sits above it.
        let backdrop = UIView(frame: tableView.bounds)
        backdrop.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backdrop.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .secondaryColor
        Utils.addBackground(view: backdrop)

        // Sized by frame, not constraints: a table places its background view itself.
        page.frame = backdrop.bounds
        page.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backdrop.addSubview(page)
        tableView.backgroundView = backdrop
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        refreshFriendshipButton()
        applyStrangerLimits()
    }

    private func centred(_ view: UIView, size: CGFloat) -> UIView {
        let box = UIView()
        box.addSubview(view)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            view.topAnchor.constraint(equalTo: box.topAnchor),
            view.bottomAnchor.constraint(equalTo: box.bottomAnchor),
            view.widthAnchor.constraint(equalToConstant: size),
            view.heightAnchor.constraint(equalToConstant: size)
        ])
        return box
    }

    /// A row that sits in the middle of its box rather than being stretched across it, so the
    /// mark and the name read as one thing.
    private func centredRow(_ row: UIView) -> UIView {
        let box = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(row)
        NSLayoutConstraint.activate([
            row.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            row.topAnchor.constraint(equalTo: box.topAnchor),
            row.bottomAnchor.constraint(equalTo: box.bottomAnchor),
            row.leadingAnchor.constraint(greaterThanOrEqualTo: box.leadingAnchor),
            row.trailingAnchor.constraint(lessThanOrEqualTo: box.trailingAnchor)
        ])
        return box
    }

    private func padded(_ view: UIView) -> UIView {
        let box = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 24),
            view.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -24),
            view.topAnchor.constraint(equalTo: box.topAnchor),
            view.bottomAnchor.constraint(equalTo: box.bottomAnchor)
        ])
        return box
    }

    /// Audio, Video, and adding or removing the person as a friend.
    private func buildActionRow() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 10

        let audio = actionTile(symbol: "phone.fill", title: "Audio".localized(), action: #selector(call(sender:)))
        let camera = actionTile(symbol: "video.fill", title: "Video".localized(), action: #selector(video(sender:)))
        audioTile = audio
        videoTile = camera
        row.addArrangedSubview(audio)
        row.addArrangedSubview(camera)
        let friendship = actionTile(symbol: "person.badge.plus", title: "Friend".localized(), action: #selector(tapFriendship))
        friendshipTile = friendship
        row.addArrangedSubview(friendship)
        return padded(row)
    }

    private func actionTile(symbol: String, title: String, action: Selector) -> UIControl {
        let tile = ProfileActionTile()
        tile.icon.image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular))
        tile.caption.text = title
        tile.addTarget(self, action: action, for: .touchUpInside)
        tile.heightAnchor.constraint(equalToConstant: 62).isActive = true
        return tile
    }

    /// Which of the two the third button is offering, and what it says.
    func refreshFriendshipButton() {
        guard let tile = friendshipTile as? ProfileActionTile else {
            return
        }
        let isFriend = flag == .friend
        tile.icon.image = UIImage(systemName: isFriend ? "person.badge.minus" : "person.badge.plus",
                                  withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular))
        tile.caption.text = isFriend ? "Unfriend".localized() : "Friend".localized()
        tile.tintColor = isFriend ? .systemRed : .systemBlue
    }

    /// What somebody who is not a friend yet can be offered.
    ///
    /// There is no conversation with them, so there are no media, no links, no documents and
    /// nothing starred - the card would open onto empty screens. Calling them is not on offer
    /// either; adding them as a friend is the one thing this screen is for.
    func applyStrangerLimits() {
        guard flag != .me else {
            return
        }
        let isFriend = flag == .friend
        profileCard?.isHidden = !isFriend
        for tile in [audioTile, videoTile] {
            tile?.isEnabled = isFriend
            tile?.alpha = isFriend ? 1 : 0.4
        }
    }

    @objc func tapFriendship() {
        if flag == .friend {
            didTapUnfriend(sender: self)
        } else {
            didTapAdd(sender: self)
        }
    }

    private func buildLinksCard() -> UIView {
        let card = UIStackView()
        card.axis = .vertical
        card.spacing = 0
        card.backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.08) : .white }
        card.layer.cornerRadius = 12
        // Clipped so the rows inside keep the rounded corners - which is exactly why the shadow
        // cannot live on this view: a shadow is drawn outside the bounds it is clipped to.
        card.clipsToBounds = true

        card.addArrangedSubview(cardRow(symbol: "photo.on.rectangle",
                                        title: "Media, links and docs".localized(),
                                        action: #selector(tapConversationMedia)))
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        card.addArrangedSubview(divider)
        card.addArrangedSubview(cardRow(symbol: "star",
                                        title: "Starred Messages".localized(),
                                        action: #selector(tapStarred)))
        let lifted = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        lifted.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: lifted.topAnchor),
            card.bottomAnchor.constraint(equalTo: lifted.bottomAnchor),
            card.leadingAnchor.constraint(equalTo: lifted.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: lifted.trailingAnchor)
        ])
        ProfileCardStyle.lift(lifted, radius: 12)
        return padded(lifted)
    }

    func cardRow(symbol: String, title: String, action: Selector? = nil, value: String? = nil, accessory: UIView? = nil) -> ProfileCardRow {
        let row = ProfileCardRow(accessory: accessory)
        row.icon.image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular))
        row.caption.text = title
        row.value.text = value
        if let action = action {
            row.addTarget(self, action: action, for: .touchUpInside)
        }
        row.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return row
    }

    func cardDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return divider
    }

    /// The card of settings the reader keeps for their own account.
    ///
    /// The switches and the buttons are the ones the storyboard made - moved in here rather than
    /// built again, so everything already wired to them keeps working untouched.
    private func buildMyCard() -> UIView {
        let card = UIStackView()
        card.axis = .vertical
        card.spacing = 0
        card.backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.08) : .white }
        card.layer.cornerRadius = 12
        card.clipsToBounds = true

        let status = cardRow(symbol: "quote.bubble", title: "Status".localized(),
                             action: #selector(tapEditStatus),
                             value: (user?.status ?? "").isEmpty ? "Write a status".localized() : user?.status)
        myStatusRow = status
        card.addArrangedSubview(status)
        card.addArrangedSubview(cardDivider())

        card.addArrangedSubview(cardRow(symbol: "lock.shield", title: "Private Account Mode".localized(),
                                        accessory: switchPrivateAccount))
        card.addArrangedSubview(cardDivider())
        card.addArrangedSubview(cardRow(symbol: "key", title: "Change Password".localized(),
                                        action: #selector(editPassword(sender:))))
        card.addArrangedSubview(cardDivider())
        card.addArrangedSubview(cardRow(symbol: "phone.arrow.down.left", title: "Accept Call".localized(),
                                        accessory: switchAcceptCall))
        if !(buttonHistoryCC?.isHidden ?? true) {
            card.addArrangedSubview(cardDivider())
            card.addArrangedSubview(cardRow(symbol: "clock.arrow.circlepath", title: "Call Center History".localized(),
                                            action: #selector(historyCC(sender:))))
        }

        let lifted = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        lifted.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: lifted.topAnchor),
            card.bottomAnchor.constraint(equalTo: lifted.bottomAnchor),
            card.leadingAnchor.constraint(equalTo: lifted.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: lifted.trailingAnchor)
        ])
        ProfileCardStyle.lift(lifted, radius: 12)
        return padded(lifted)
    }

    /// Editing the status without a screen of its own: the field the storyboard made is still what
    /// saves it, so the words typed here are handed to it and the same save runs.
    @objc func tapEditStatus() {
        let alert = UIAlertController(title: "Status".localized(), message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.text = self.user?.status
            field.placeholder = "Write a status".localized()
        }
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel))
        alert.addAction(UIAlertAction(title: "Save".localized(), style: .default) { [weak self] _ in
            guard let self = self else {
                return
            }
            let text = alert.textFields?.first?.text ?? ""
            self.editTextStatus?.text = text
            self.saveStatus(sender: self)
            self.myStatusRow?.value.text = text.isEmpty ? "Write a status".localized() : text
        })
        present(alert, animated: true)
    }
}

/// How the panels on this screen are set apart from whatever is behind them.
///
/// The background is the app's own artwork and can be anything - pale, busy, white. A panel that
/// relies on its fill alone disappears against a light one, so each carries a soft shadow and a
/// hairline. The shadow does the work on a light background; the hairline does it on a dark one,
/// where a shadow shows nothing at all.
enum ProfileCardStyle {

    /// A halo behind the letters, so the name and the status hold up over any background.
    ///
    /// The colour is the opposite of the text's, not simply black: the name is drawn in `.label`,
    /// which is dark in a light theme and light in a dark one, and a dark shadow behind dark
    /// letters would do nothing. It sits behind the glyphs only, so the background is untouched.
    static func halo(_ label: UILabel) {
        label.layer.shadowColor = label.traitCollection.userInterfaceStyle == .dark
            ? UIColor.black.cgColor
            : UIColor.white.cgColor
        label.layer.shadowOpacity = 0.8
        label.layer.shadowRadius = 3
        label.layer.shadowOffset = .zero
        label.layer.masksToBounds = false
    }

    static func lift(_ view: UIView, radius: CGFloat = 12) {
        view.layer.cornerRadius = radius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.12
        view.layer.shadowRadius = 6
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.12) : UIColor(white: 0, alpha: 0.06)
        }.cgColor
    }
}

/// One of the three things that can be done with a person.
final class ProfileActionTile: UIControl {
    let icon = UIImageView()
    let caption = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.08) : .white }
        layer.cornerRadius = 12
        ProfileCardStyle.lift(self)
        tintColor = .systemBlue
        icon.contentMode = .center
        icon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(icon)
        caption.font = .systemFont(ofSize: 12)
        caption.textAlignment = .center
        caption.translatesAutoresizingMaskIntoConstraints = false
        addSubview(caption)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: centerXAnchor),
            icon.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            caption.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 5),
            caption.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            caption.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
        ])
        // The whole tile takes the tint, so the icon and the word agree with each other.
        caption.textColor = tintColor
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        caption.textColor = tintColor
    }
}

/// One line of the card beneath: an icon, a name, what it is set to, and something on the right -
/// a chevron by default, or a switch where the line is a setting rather than a way through.
final class ProfileCardRow: UIControl {
    let icon = UIImageView()
    let caption = UILabel()
    let value = UILabel()

    init(accessory: UIView? = nil) {
        self.accessory = accessory
        super.init(frame: .zero)
        build()
    }

    private let accessory: UIView?

    override init(frame: CGRect) {
        self.accessory = nil
        super.init(frame: frame)
        build()
    }

    private func build() {
        icon.tintColor = .secondaryLabel
        icon.contentMode = .center
        icon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(icon)
        caption.font = .systemFont(ofSize: 16)
        caption.textColor = .label
        caption.translatesAutoresizingMaskIntoConstraints = false
        addSubview(caption)
        value.font = .systemFont(ofSize: 15)
        value.textColor = .secondaryLabel
        value.textAlignment = .right
        value.translatesAutoresizingMaskIntoConstraints = false
        addSubview(value)

        let right: UIView
        if let accessory = accessory {
            // A switch belongs to the storyboard and may already be somewhere else.
            accessory.removeFromSuperview()
            right = accessory
        } else {
            let chevron = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)))
            chevron.tintColor = .tertiaryLabel
            right = chevron
        }
        right.translatesAutoresizingMaskIntoConstraints = false
        right.setContentHuggingPriority(.required, for: .horizontal)
        addSubview(right)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            caption.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            caption.centerYAnchor.constraint(equalTo: centerYAnchor),
            right.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            right.centerYAnchor.constraint(equalTo: centerYAnchor),
            value.trailingAnchor.constraint(equalTo: right.leadingAnchor, constant: -8),
            value.centerYAnchor.constraint(equalTo: centerYAnchor),
            value.leadingAnchor.constraint(greaterThanOrEqualTo: caption.trailingAnchor, constant: 8)
        ])
        caption.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        return nil
    }
}

extension ProfileViewController {

    /// Everything this conversation has ever attached.
    @objc func tapConversationMedia() {
        guard let pin = user?.pin, !pin.isEmpty else {
            return
        }
        let browser = MediaBrowserViewController()
        browser.conversationName = name
        let rows = personalMessageRows()
        browser.media = rows.compactMap { row in
            let thumb = row["thumb_id"] as? String ?? ""
            let video = row["video_id"] as? String ?? ""
            let image = row["image_id"] as? String ?? ""
            guard !thumb.isEmpty, !(video.isEmpty && image.isEmpty) else {
                return nil
            }
            return MediaBrowserViewController.MediaItem(
                messageId: row["message_id"] as? String ?? "",
                thumbFileName: thumb,
                mediaFileName: video.isEmpty ? image : video,
                isVideo: !video.isEmpty,
                durationSeconds: Int(row["video_duration"] as? Int32 ?? 0),
                date: Double(row["server_date"] as? String ?? "") ?? 0)
        }
        for row in rows {
            let messageId = row["message_id"] as? String ?? ""
            let when = Double(row["server_date"] as? String ?? "") ?? 0
            let text = row["message_text"] as? String ?? ""
            let file = row["file_id"] as? String ?? ""
            if !file.isEmpty {
                let parts = text.components(separatedBy: "|")
                browser.docs.append(MediaBrowserViewController.DocItem(messageId: messageId,
                                                                       fileName: parts.first ?? file,
                                                                       storedName: file,
                                                                       detail: parts.count > 1 ? parts[1] : "",
                                                                       date: when))
            } else if let url = MediaBrowserViewController.firstLink(in: text) {
                browser.links.append(MediaBrowserViewController.LinkItem(messageId: messageId,
                                                                        url: url,
                                                                        caption: text,
                                                                        thumbFileName: row["thumb_id"] as? String ?? "",
                                                                        date: when))
            }
        }
        // There is no conversation on screen here to hand a picture to, so one is made and kept
        // behind the browser - loaded, but never shown. It is only ever asked to open a picture,
        // and it does that over the browser: the viewer grows out of the square that was tapped
        // and closing it comes back to the grid, while every button on it is the conversation's
        // own. Pushing the conversation instead gave the wrong animation and the wrong way back.
        //
        // Fix: this used to push it, which is why opening a picture looked like opening a chat.
        if let pin = user?.pin, !pin.isEmpty {
            let conversation = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
            conversation.unique_l_pin = pin
            conversation.isBackgroundHelper = true
            // Wrapped in a navigation controller of its own, and that is what is added.
            //
            // Fix: added directly, it shared the browser's navigation controller - so it styled
            // the real bar as a conversation does, and put its own bar up as well. That is the
            // second bar that appeared, and why the profile's bar came back a different colour.
            // Inside its own, `navigationController` means that one and nothing it does is seen.
            let hidden = UINavigationController(rootViewController: conversation)
            hidden.setNavigationBarHidden(true, animated: false)
            browser.addChild(hidden)
            hidden.view.frame = browser.view.bounds
            hidden.view.isHidden = true
            browser.view.addSubview(hidden.view)
            browser.view.sendSubviewToBack(hidden.view)
            hidden.didMove(toParent: browser)

            // Going to a message leaves this screen and the browser behind, so backing out of the
            // conversation returns to wherever the profile was opened from rather than dropping
            // the reader back onto a grid of pictures they have finished with.
            conversation.onNeedsRealConversation = { [weak self, weak browser] messageId in
                guard let self = self, let stack = self.navigationController else {
                    return
                }
                // Fix: a new conversation was made every time, and this screen is usually opened
                // from that very conversation - so the stack ended up holding two of them, one
                // behind the other. If it is already down there, that is the one to go back to.
                if let already = stack.viewControllers.compactMap({ $0 as? EditorPersonal })
                    .last(where: { $0.unique_l_pin == pin && !$0.isBackgroundHelper }) {
                    CATransaction.begin()
                    CATransaction.setCompletionBlock {
                        already.highlightMessage(messageId)
                    }
                    stack.popToViewController(already, animated: true)
                    CATransaction.commit()
                    return
                }
                let real = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                real.unique_l_pin = pin
                real.hidesBottomBarWhenPushed = true
                // Handled while it loads, the same way a search result is - scrolled to and
                // flashed - rather than jumped to once it is already on screen.
                real.referenceMessageId = messageId
                var stacked = stack.viewControllers
                stacked.removeAll { $0 === self || $0 === browser }
                stacked.append(real)
                stack.setViewControllers(stacked, animated: true)
            }

            browser.onOpenMedia = { [weak browser, weak conversation] messageId in
                guard let browser = browser, let conversation = conversation else {
                    return
                }
                conversation.openMedia(messageId: messageId,
                                       from: browser,
                                       origin: browser.tileView(for: messageId))
            }
        }
        navigationController?.pushViewController(browser, animated: true)
    }

    /// Everything of this conversation the reader has kept.
    @objc func tapStarred() {
        navigationController?.pushViewController(Nexilis.getEditorStarMessage(), animated: true)
    }

    /// The attachments of this conversation, read straight from the database.
    ///
    /// The profile is not a conversation screen and has no window of messages to draw on, so the
    /// rows it needs are asked for here - and only the rows that carry something.
    private func personalMessageRows() -> [[String: Any?]] {
        guard let pin = user?.pin, !pin.isEmpty else {
            return []
        }
        var rows: [[String: Any?]] = []
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            let scopes = "(message_scope_id = '\(MessageScope.WHISPER)' OR message_scope_id = '\(MessageScope.FORM)')"
            let query = """
                SELECT message_id, server_date, message_text, image_id, video_id, thumb_id, file_id, video_duration \
                FROM MESSAGE where (f_pin='\(pin)' or l_pin='\(pin)') AND \(scopes) AND is_call_center = 0 \
                AND (lock IS NULL OR lock <> '1') AND (credential IS NULL OR credential <> '1') \
                AND ((thumb_id IS NOT NULL AND thumb_id <> '') OR (file_id IS NOT NULL AND file_id <> '') \
                OR message_text LIKE '%http://%' OR message_text LIKE '%https://%') \
                order by server_date asc
                """
            guard let cursor = Database.shared.getRecords(fmdb: fmdb, query: query) else {
                return
            }
            while cursor.next() {
                var row: [String: Any?] = [:]
                row["message_id"] = cursor.string(forColumnIndex: 0)
                row["server_date"] = cursor.string(forColumnIndex: 1)
                row["message_text"] = cursor.string(forColumnIndex: 2)
                row["image_id"] = cursor.string(forColumnIndex: 3)
                row["video_id"] = cursor.string(forColumnIndex: 4)
                row["thumb_id"] = cursor.string(forColumnIndex: 5)
                row["file_id"] = cursor.string(forColumnIndex: 6)
                row["video_duration"] = cursor.int(forColumnIndex: 7)
                rows.append(row)
            }
            cursor.close()
        })
        return rows
    }
}
