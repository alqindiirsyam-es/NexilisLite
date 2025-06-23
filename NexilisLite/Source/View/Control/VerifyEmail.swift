//
//  VerifyEmail.swift
//  NexilisLite
//
//  Created by Akhmad Al Qindi Irsyam on 28/10/22.
//

import UIKit
import NotificationBannerSwift

class VerifyEmail: UIViewController, UITextFieldDelegate, OTPTextFieldDelegate {
    var initialBounds: CGRect?
    var email = ""
    var msisdn = ""
    let txtField1 = OTPTextField()
    let txtField2 = OTPTextField()
    let txtField3 = OTPTextField()
    let txtField4 = OTPTextField()
    let txtField5 = OTPTextField()
    let txtField6 = OTPTextField()
    var firstLoad = true
    var isDismiss: ((String) -> ())?
    var showWrongOTP = ""
    var isMSISDN = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        let topIndicator = UIView()
        topIndicator.backgroundColor = .lightGray.withAlphaComponent(0.5)
        topIndicator.layer.cornerRadius = 5
        topIndicator.layer.masksToBounds = true
        view.addSubview(topIndicator)
        topIndicator.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 20, centerX: view.centerXAnchor, width: 80, height: 10)
        
        let titleVerify = UILabel()
        titleVerify.font = .systemFont(ofSize: 14, weight: .medium)
        titleVerify.text = "Verification Code".localized()
        view.addSubview(titleVerify)
        titleVerify.anchor(top: topIndicator.bottomAnchor, paddingTop: 8, centerX: view.centerXAnchor)
        
        let descVerify = UILabel()
        descVerify.font = .systemFont(ofSize: 12)
        descVerify.numberOfLines = 0
        descVerify.textAlignment = .center
        descVerify.text = "Your verification code has been sent to".localized() + "\n" + email + "\n" + "Please check your email and enter the code sent".localized()
        if isMSISDN {
            descVerify.text = "Your verification code has been sent to".localized() + "\n" + msisdn + "\n" + "Please check in your message app and enter the code sent".localized()
        }
        view.addSubview(descVerify)
        descVerify.anchor(top: titleVerify.bottomAnchor, paddingTop: 8, centerX: view.centerXAnchor)
        
        let containerTxt = UIView()
        view.addSubview(containerTxt)
        containerTxt.anchor(top: descVerify.bottomAnchor, paddingTop: 20, centerX: view.centerXAnchor, width: 340, height: 60)
        
        
        txtField1.backgroundColor = .lightGray.withAlphaComponent(0.5)
        txtField1.textAlignment = .center
        txtField1.font = .systemFont(ofSize: 16)
        txtField1.keyboardType = .numberPad
        txtField1.layer.cornerRadius = 5
        txtField1.layer.masksToBounds = true
        txtField1.delegate = self
        txtField1.myDelegate = self
        containerTxt.addSubview(txtField1)
        txtField1.anchor(left: containerTxt.leftAnchor, centerY: containerTxt.centerYAnchor, width: 50, height: 60)
        
        txtField2.backgroundColor = .lightGray.withAlphaComponent(0.5)
        txtField2.textAlignment = .center
        txtField2.keyboardType = .numberPad
        txtField2.font = .systemFont(ofSize: 16)
        txtField2.layer.cornerRadius = 5
        txtField2.layer.masksToBounds = true
        txtField2.delegate = self
        txtField2.myDelegate = self
        containerTxt.addSubview(txtField2)
        txtField2.anchor(left: txtField1.rightAnchor, paddingLeft: 8, centerY: containerTxt.centerYAnchor, width: 50, height: 60)
        
        txtField3.backgroundColor = .lightGray.withAlphaComponent(0.5)
        txtField3.textAlignment = .center
        txtField3.keyboardType = .numberPad
        txtField3.font = .systemFont(ofSize: 16)
        txtField3.layer.cornerRadius = 5
        txtField3.layer.masksToBounds = true
        txtField3.delegate = self
        txtField3.myDelegate = self
        containerTxt.addSubview(txtField3)
        txtField3.anchor(left: txtField2.rightAnchor, paddingLeft: 8, centerY: containerTxt.centerYAnchor, width: 50, height: 60)
        
        txtField4.backgroundColor = .lightGray.withAlphaComponent(0.5)
        txtField4.textAlignment = .center
        txtField4.keyboardType = .numberPad
        txtField4.font = .systemFont(ofSize: 16)
        txtField4.layer.cornerRadius = 5
        txtField4.layer.masksToBounds = true
        txtField4.delegate = self
        txtField4.myDelegate = self
        containerTxt.addSubview(txtField4)
        txtField4.anchor(left: txtField3.rightAnchor, paddingLeft: 8, centerY: containerTxt.centerYAnchor, width: 50, height: 60)
        
        txtField5.backgroundColor = .lightGray.withAlphaComponent(0.5)
        txtField5.textAlignment = .center
        txtField5.keyboardType = .numberPad
        txtField5.font = .systemFont(ofSize: 16)
        txtField5.layer.cornerRadius = 5
        txtField5.layer.masksToBounds = true
        txtField5.delegate = self
        txtField5.myDelegate = self
        containerTxt.addSubview(txtField5)
        txtField5.anchor(left: txtField4.rightAnchor, paddingLeft: 8, centerY: containerTxt.centerYAnchor, width: 50, height: 60)
        
        txtField6.backgroundColor = .lightGray.withAlphaComponent(0.5)
        txtField6.textAlignment = .center
        txtField6.keyboardType = .numberPad
        txtField6.font = .systemFont(ofSize: 16)
        txtField6.layer.cornerRadius = 5
        txtField6.layer.masksToBounds = true
        txtField6.delegate = self
        txtField6.myDelegate = self
        containerTxt.addSubview(txtField6)
        txtField6.anchor(left: txtField5.rightAnchor, paddingLeft: 8, centerY: containerTxt.centerYAnchor, width: 50, height: 60)
        
        txtField1.becomeFirstResponder()
        
        if !showWrongOTP.isEmpty {
            if showWrongOTP == "3t" {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Expired OTP".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
            } else {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Invalid OTP".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (string.count == 1){
            if textField == txtField1 {
               txtField2.becomeFirstResponder()
            }
            if textField == txtField2 {
               txtField3.becomeFirstResponder()
            }
            if textField == txtField3 {
               txtField4.becomeFirstResponder()
            }
            if textField == txtField4 {
                txtField5.becomeFirstResponder()
            }
            if textField == txtField5 {
                txtField6.becomeFirstResponder()
            }
            if textField == txtField6 {
               textField.text? = string
                txtField6.resignFirstResponder()
                self.dismiss(animated: true, completion: {
                    self.isDismiss?("\(self.txtField1.text!)\(self.txtField2.text!)\(self.txtField3.text!)\(self.txtField4.text!)\(self.txtField5.text!)\(self.txtField6.text!)")
                })
               return false
            }
            textField.text? = string
            return false
       } else {
            if textField == txtField1 {
               txtField1.becomeFirstResponder()
            }
            if textField == txtField2 {
               txtField1.becomeFirstResponder()
            }
            if textField == txtField3 {
               txtField2.becomeFirstResponder()
            }
            if textField == txtField4 {
               txtField3.becomeFirstResponder()
            }
            if textField == txtField5 {
              txtField4.becomeFirstResponder()
            }
            if textField == txtField6 {
              txtField5.becomeFirstResponder()
            }
            textField.text? = string
            return false
       }
    }
    
    func textFieldDidDelete() {
        if txtField2.isFirstResponder && txtField2.text!.isEmpty {
            txtField1.text = ""
            txtField1.becomeFirstResponder()
        } else if txtField3.isFirstResponder && txtField3.text!.isEmpty {
            txtField2.text = ""
            txtField2.becomeFirstResponder()
        } else if txtField4.isFirstResponder && txtField4.text!.isEmpty {
            txtField3.text = ""
            txtField3.becomeFirstResponder()
        } else if txtField5.isFirstResponder && txtField5.text!.isEmpty {
            txtField4.text = ""
            txtField4.becomeFirstResponder()
        } else if txtField6.isFirstResponder && txtField6.text!.isEmpty {
            txtField5.text = ""
            txtField5.becomeFirstResponder()
        }
    }
    
    override func viewDidLayoutSubviews() {
        if firstLoad {
            firstLoad = false
            view.layer.cornerRadius = 20
            view.layer.masksToBounds = true
            view.frame = CGRect(x: 0, y: view.bounds.height / 5 * 2 - 50, width: view.bounds.width, height: view.bounds.height / 5 * 3 + 50)
        }
    }
}

protocol OTPTextFieldDelegate: AnyObject {
    func textFieldDidDelete()
}

class OTPTextField: UITextField {

    weak var myDelegate: OTPTextFieldDelegate?

    override func deleteBackward() {
        super.deleteBackward()
        myDelegate?.textFieldDidDelete()
    }
}
