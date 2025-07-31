//
//  CommunityNew.swift
//  Pods
//
//  Created by Qindi on 26/05/25.
//

import Foundation
import UIKit
import NotificationBannerSwift

public class CommunityNew: UIViewController, UITextFieldDelegate  {
    
    let containerButton = UIView()
    let buttonComm = UIButton(type: .custom)
    let scrollView = UIScrollView()
    var bottomConstButton: NSLayoutConstraint!
    let fieldName = UITextField()
    let fieldDesc = UITextView()
    var thumb = ""
    
    public override func viewDidLoad() {
        setUpHeader()
        view.backgroundColor = .whiteBubbleColor
        setupScrollView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                                   name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                                   name: UIResponder.keyboardWillHideNotification, object: nil)
        
        fieldName.becomeFirstResponder()
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        let info:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardHeight: CGFloat = keyboardSize.height
        let duration: CGFloat = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber as! CGFloat
        let bottomInset = keyboardHeight

        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight + 550, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        bottomConstButton.constant = -bottomInset
        var indicatorInsets = scrollView.verticalScrollIndicatorInsets
        indicatorInsets.bottom = bottomInset
        UIView.animate(withDuration: TimeInterval(duration), animations: {
            self.view.layoutIfNeeded()
        })
        scrollView.verticalScrollIndicatorInsets = indicatorInsets
        if let activeField = view.currentFirstResponder() {
            scrollView.scrollRectToVisible(activeField.frame, animated: true)
        }
    }

    @objc func keyboardWillHide(notification: Notification) {
        let contentInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        bottomConstButton.constant = 0
    }
    
    func setUpHeader() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(cancel(sender:)))
        self.navigationController?.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black]
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black, NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.titleTextAttributes = attributes
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle == .dark ? .dark : .light
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        tabBarController?.navigationItem.leftBarButtonItem = nil
        tabBarController?.navigationItem.searchController = nil
        
        self.navigationController?.navigationBar.topItem?.title = "New Community".localized()
        self.navigationController?.navigationBar.setNeedsLayout()
    }
    
    func setupScrollView() {
        scrollView.alwaysBounceHorizontal = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.isScrollEnabled = true
        view.addSubview(scrollView)
        scrollView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingBottom: 60)
        
        view.addSubview(containerButton)
        containerButton.anchor(left: view.leftAnchor, right: view.rightAnchor, height: 60)
        containerButton.backgroundColor = .whiteBubbleColor
        bottomConstButton = containerButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        bottomConstButton.isActive = true
        
        let ppView = UIImageView()
        ppView.backgroundColor = .whatsappGrayPPColor
        scrollView.addSubview(ppView)
        ppView.anchor(top: scrollView.topAnchor, paddingTop: 80, centerX: scrollView.centerXAnchor, width: 120, height: 120)
        ppView.layer.cornerRadius = 25
        ppView.clipsToBounds = true
        ppView.image = UIImage(systemName: "person.3.fill")
        ppView.tintColor = .white
        ppView.contentMode = .scaleAspectFit
        
        let buttonAddPP = UIButton()
        scrollView.addSubview(buttonAddPP)
        buttonAddPP.setTitle("Add Photo".localized(), for: .normal)
        buttonAddPP.setTitleColor(.whatsappGreenColor, for: .normal)
        buttonAddPP.titleLabel?.font = .systemFont(ofSize: 16)
        buttonAddPP.anchor(top: ppView.bottomAnchor, paddingTop: 5, centerX: scrollView.centerXAnchor)
        
        scrollView.addSubview(fieldName)
        fieldName.font = .systemFont(ofSize: 14)
        fieldName.placeholder = "Community Name".localized()
        fieldName.backgroundColor = .white
        fieldName.anchor(top: buttonAddPP.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 10, paddingLeft: 20, paddingRight: 20, height: 45)
        fieldName.layer.cornerRadius = 10
        fieldName.clipsToBounds = true
        fieldName.tintColor = .whatsappGreenColor
        fieldName.textColor = .black
        fieldName.addTarget(self, action: #selector(didChanged(sender:)), for: .editingChanged)
        fieldName.delegate = self
        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        fieldName.leftView = leftPadding
        fieldName.leftViewMode = .always
        let rightPadding = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        fieldName.rightView = rightPadding
        fieldName.rightViewMode = .always
        
        scrollView.addSubview(fieldDesc)
        fieldDesc.font = .systemFont(ofSize: 14)
        fieldDesc.backgroundColor = .white
        fieldDesc.anchor(top: fieldName.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 20, paddingLeft: 20, paddingRight: 20, height: 135)
        fieldDesc.layer.cornerRadius = 10
        fieldDesc.clipsToBounds = true
        fieldDesc.tintColor = .whatsappGreenColor
        fieldDesc.textColor = .black
        fieldDesc.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        fieldDesc.textContainer.lineFragmentPadding = 0
        fieldDesc.text = "Hi everyone! This community is for members to chat in topic-based groups and get important announcements.".localized()
        
        containerButton.addSubview(buttonComm)
        buttonComm.anchor(top: containerButton.topAnchor, left: containerButton.leftAnchor, right: containerButton.rightAnchor, paddingTop: 5, paddingLeft: 30, paddingRight: 30, height: 45)
        buttonComm.backgroundColor = .waGrayLight
        buttonComm.setTitleColor(.waGrayFont, for: .normal)
        buttonComm.layer.cornerRadius = 15
        buttonComm.clipsToBounds = true
        buttonComm.setTitle("Create Community".localized(), for: .normal)
        buttonComm.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        buttonComm.isEnabled = false
//        buttonComm.addTarget(self, action: #selector(didSubmit), for: .touchUpInside)
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField != fieldName {
            return true
        }
        guard let currentText = textField.text else { return true }
        let newLength = currentText.count + string.count - range.length
        return newLength <= 100
    }

    @objc func didChanged(sender: Any) {
        if let text = fieldName.text, text.trimmingCharacters(in: .whitespaces).isEmpty {
            buttonComm.backgroundColor = .waGrayLight
            buttonComm.setTitleColor(.waGrayFont, for: .normal)
        } else {
            buttonComm.backgroundColor = .whatsappGreenColor
            buttonComm.setTitleColor(.white, for: .normal)
        }
    }
    
    @objc func cancel(sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func didSubmit(sender: Any) {
        if let text = fieldName.text {
            buttonComm.backgroundColor = .waGrayLight
            buttonComm.setTitleColor(.waGrayFont, for: .normal)
            
            Nexilis.showLoader()
            DispatchQueue.global().async {
                if let resp = Nexilis.writeSync(message: CoreMessage_TMessageBank.getCreateCommunity(pCommunityName: text, pCommunityDesc: self.fieldDesc.text ?? "", pCommunityThumbId: self.thumb)) {
                    if resp.isOk() {
                        let communityId = resp.getBody(key: CoreMessage_TMessageKey.COMMUNITY_ID, default_value: "")
                        if communityId.isEmpty {
                            DispatchQueue.main.async {
                                Nexilis.hideLoader(completion: {
                                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                    imageView.tintColor = .white
                                    let banner = FloatingNotificationBanner(title: "Failed to create community, please try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                                    banner.show()
                                })
                            }
                            return
                        }
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            let me = User.getMyPin() ?? ""
                            let createdDate = Date().currentTimeMillis()
                            if let dataMe = User.getData(pin: me, fmdb: fmdb) {
                                do {
                                    _ = try Database.shared.insertRecord(fmdb: fmdb, table: "COMMUNITY", cvalues: [
                                        "community_id" : communityId,
                                        "f_name" : text,
                                        "image_id": self.thumb,
                                        "quote": self.fieldDesc.text ?? "",
                                        "created_by" : me,
                                        "created_date" : "\(createdDate)",
                                        "community_type" : 0,
                                        "level" : 1,
                                        "be" : dataMe.beId
                                    ], replace: true)
                                    
                                    _ = try Database.shared.insertRecord(fmdb: fmdb, table: "COMMUNITY_MEMBER", cvalues: [
                                        "community_id" :communityId,
                                        "f_pin" : me,
                                        "position" : 1,
                                        "user_id" : me,
                                        "ac" : "",
                                        "ac_desc" : "",
                                        "first_name" : dataMe.firstName,
                                        "last_name" : dataMe.lastName,
                                        "msisdn" : "",
                                        "thumb_id" : dataMe.thumb,
                                        "created_date" : "\(createdDate)"
                                    ], replace: true)
                                } catch {
                                    rollback.pointee = true
                                    print("Access database error: \(error.localizedDescription)")
                                }
                                
                            }
                        })
                    } else {
                        DispatchQueue.main.async {
                            Nexilis.hideLoader(completion: {
                                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Failed to create community, please try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                                banner.show()
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
        
    }
}
