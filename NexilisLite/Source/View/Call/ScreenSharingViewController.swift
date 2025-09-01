//
//  ScreenSharingViewController.swift
//  NexilisLite
//
//  Created by Akhmad Al Qindi Irsyam on 06/06/23.
//

import UIKit
import nuSDKService

class ScreenSharingViewController: UIViewController {
    
    var fromContact: Int?
    let myImage = UIImageView()
    let name = UILabel()
    let profileImage = UIImageView()
    let labelIncomingOutgoing = UILabel()
    var user: User?
    let buttonDecline = UIButton()
    let buttonAccept = UIButton()
    var constraintLeadingButtonDecline = NSLayoutConstraint()
    var constraintBottomButtonDecline = NSLayoutConstraint()
    var imageSS = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        if fromContact != nil {
            addBackgroundIncoming()
            addProfileNameCalling()
            Calling()
            addToolbar()
        }
        self.view.backgroundColor = .white
        self.title = "Screen Sharing".localized()
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(ssSession(notification:)), name: NSNotification.Name(rawValue: "ssSession"), object: nil)
    }
    
    func addBackgroundIncoming() {
        view.addSubview(myImage)
        myImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            myImage.topAnchor.constraint(equalTo: view.topAnchor),
            myImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            myImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            myImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        myImage.backgroundColor = .lightGray
        myImage.tintColor = .secondaryColor
        let image = user!.thumb
        if image.isEmpty {
            myImage.image = UIImage(systemName: "person")
            myImage.contentMode = .scaleAspectFit
        } else {
            myImage.setImage(name: image)
            myImage.contentMode = .scaleAspectFill
        }
    }
    
    func addProfileNameCalling() {
        view.addSubview(profileImage)
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        profileImage.frame.size = CGSize(width: 60.0, height: 60.0)
        NSLayoutConstraint.activate([
            profileImage.topAnchor.constraint(equalTo: view.topAnchor, constant: 40.0),
            profileImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImage.widthAnchor.constraint(equalToConstant: 60.0),
            profileImage.heightAnchor.constraint(equalToConstant: 63.0)
        ])
        profileImage.backgroundColor = .lightGray
        profileImage.tintColor = .secondaryColor
        profileImage.circle()
        let image = user!.thumb
        if image.isEmpty {
            profileImage.image = UIImage(systemName: "person")
            profileImage.contentMode = .scaleAspectFit
            profileImage.layer.borderWidth = 1
            profileImage.layer.borderColor = UIColor.secondaryColor.cgColor
        } else {
            profileImage.setImage(name: image)
            profileImage.contentMode = .scaleAspectFill
        }
        
        view.addSubview(name)
        name.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            name.topAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: 5.0),
            name.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        name.font = UIFont.systemFont(ofSize: 12)
        name.backgroundColor = .black.withAlphaComponent(0.05)
        name.layer.cornerRadius = 5.0
        name.clipsToBounds = true
        name.textColor = .mainColor
        name.text = user?.fullName.trimmingCharacters(in: .whitespaces)
    }
    
    func Calling() {
        view.addSubview(labelIncomingOutgoing)
        labelIncomingOutgoing.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelIncomingOutgoing.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 40.0),
            labelIncomingOutgoing.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        if fromContact == 0 {
            labelIncomingOutgoing.text = "Ringing".localized() + "..."
            _ = Nexilis.write(message: CoreMessage_TMessageBank.ssCreate(l_pin: user!.pin))
        } else {
            labelIncomingOutgoing.text = "Incoming Screen Sharing".localized() + "..."
        }
        labelIncomingOutgoing.font = UIFont.systemFont(ofSize: 12)
        labelIncomingOutgoing.backgroundColor = .black.withAlphaComponent(0.05)
        labelIncomingOutgoing.layer.cornerRadius = 5.0
        labelIncomingOutgoing.clipsToBounds = true
        labelIncomingOutgoing.textColor = .mainColor
    }
    
    func addToolbar() {
        view.addSubview(buttonDecline)
        buttonDecline.translatesAutoresizingMaskIntoConstraints = false
        buttonDecline.frame.size = CGSize(width: 70.0, height: 70.0)
        if fromContact == 0 {
            constraintLeadingButtonDecline = buttonDecline.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        } else {
            constraintLeadingButtonDecline = buttonDecline.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: view.frame.width * 0.2)
        }
        constraintBottomButtonDecline = buttonDecline.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60.0)
        NSLayoutConstraint.activate([
            constraintBottomButtonDecline,
            constraintLeadingButtonDecline,
            buttonDecline.widthAnchor.constraint(equalToConstant: 70.0),
            buttonDecline.heightAnchor.constraint(equalToConstant: 70.0)
        ])
        buttonDecline.backgroundColor = .red
        buttonDecline.circle()
        buttonDecline.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
        buttonDecline.tintColor = .white
        buttonDecline.addTarget(self, action: #selector(didTapDeclineCallButton(sender:)), for: .touchUpInside)
        
        if fromContact == 1 {
            view.addSubview(buttonAccept)
            buttonAccept.translatesAutoresizingMaskIntoConstraints = false
            buttonAccept.frame.size = CGSize(width: 70.0, height: 70.0)
            NSLayoutConstraint.activate([
                buttonAccept.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60.0),
                buttonAccept.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(view.frame.width * 0.2)),
                buttonAccept.widthAnchor.constraint(equalToConstant: 70.0),
                buttonAccept.heightAnchor.constraint(equalToConstant: 70.0)
            ])
            buttonAccept.backgroundColor = .greenColor
            buttonAccept.circle()
            buttonAccept.setImage(UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
            buttonAccept.tintColor = .white
            buttonAccept.addTarget(self, action: #selector(didTapAcceptCallButton), for: .touchUpInside)
        }
    }
    
    @objc func didTapDeclineCallButton(sender: Any) {
        let alert = LibAlertController(title: "End Screen Sharing Session".localized(), message: "Are you sure you want to end screen sharing session?".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: {(_) in
            if self.fromContact == 0 {
                _ = Nexilis.write(message: CoreMessage_TMessageBank.ssEnded(l_pin: self.user!.pin))
            } else {
                _ = Nexilis.write(message: CoreMessage_TMessageBank.ssReject(l_pin: self.user!.pin))
            }
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func didTapAcceptCallButton() {
        _ = Nexilis.write(message: CoreMessage_TMessageBank.ssAccept(l_pin: user!.pin))
        DispatchQueue.main.async {
            self.myImage.removeFromSuperview()
            self.name.removeFromSuperview()
            self.profileImage.removeFromSuperview()
            self.labelIncomingOutgoing.removeFromSuperview()
            self.buttonAccept.removeFromSuperview()
            NSLayoutConstraint.deactivate([
                self.constraintLeadingButtonDecline,
                self.constraintBottomButtonDecline
            ])
            self.view.addSubview(self.imageSS)
            self.imageSS.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, bottom: self.view.bottomAnchor, right: self.view.rightAnchor)
            self.imageSS.backgroundColor = .white
            self.sendJoin()
        }
    }
    
    @objc func ssSession(notification: NSNotification) {
        DispatchQueue.main.async { [self] in
            let data:[AnyHashable : Any] = notification.userInfo!
            if let message = data["message"] as? TMessage {
                let status = message.getBody(key: CoreMessage_TMessageKey.STATUS, default_value: "")
                switch (Int(status)) {
                case CoreMessage_TMessageCode.SS_ACCEPT_INCOMING:
                    //print("SS_ACCEPT_INCOMING")
                    let f_pin = message.getBody(key: CoreMessage_TMessageKey.F_USER_ID, default_value: "")
                    _ = Nexilis.write(message: CoreMessage_TMessageBank.ssOffhook(l_pin: f_pin))
                    DispatchQueue.main.async {
                        self.myImage.removeFromSuperview()
                        self.name.removeFromSuperview()
                        self.profileImage.removeFromSuperview()
                        self.labelIncomingOutgoing.removeFromSuperview()
                        NSLayoutConstraint.deactivate([
                            self.constraintLeadingButtonDecline,
                            self.constraintBottomButtonDecline
                        ])
                        let stackViewToolbar = UIStackView()
                        self.view.addSubview(stackViewToolbar)
                        stackViewToolbar.translatesAutoresizingMaskIntoConstraints = false
                        NSLayoutConstraint.activate([
                            stackViewToolbar.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                            stackViewToolbar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -60.0)
                        ])
                        stackViewToolbar.axis = .horizontal
                        stackViewToolbar.distribution = .equalSpacing
                        stackViewToolbar.alignment = .center
                        stackViewToolbar.spacing = 30
                        stackViewToolbar.addArrangedSubview(self.buttonDecline)
                        self.buttonDecline.setImage(UIImage(systemName: "phone.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
                        UIView.animate(withDuration: 1.0, animations: {
                            self.view.layoutIfNeeded()
                        })
                        
                        self.view.addSubview(self.imageSS)
                        self.imageSS.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, bottom: stackViewToolbar.topAnchor, right: self.view.rightAnchor)
                        self.imageSS.backgroundColor = .white
                        self.sendInit()
                        let labelSSInit = UILabel()
                        self.imageSS.addSubview(labelSSInit)
                        labelSSInit.anchor(centerX: self.imageSS.centerXAnchor, centerY: self.imageSS.centerYAnchor)
                        labelSSInit.font = .systemFont(ofSize: 25)
                        labelSSInit.textColor = .mainColor
                        labelSSInit.text = "You are now sharing your screen".localized()
                    }
                case CoreMessage_TMessageCode.SS_REJECT_INCOMING,CoreMessage_TMessageCode.SS_END:
                    //print("SS_END \(status)")
                    if self.labelIncomingOutgoing.isDescendant(of: self.view) {
                        self.labelIncomingOutgoing.text = "Screen Sharing session is over".localized()
                    }
                    if !self.labelIncomingOutgoing.isDescendant(of: self.view) {
                        let conainerEnd = UIView()
                        view.addSubview(conainerEnd)
                        conainerEnd.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor)
                        conainerEnd.backgroundColor = .white
                        
                        let labelEnd = UILabel()
                        conainerEnd.addSubview(labelEnd)
                        labelEnd.anchor(centerX: conainerEnd.centerXAnchor, centerY: conainerEnd.centerYAnchor)
                        labelEnd.font = .systemFont(ofSize: 25)
                        labelEnd.textColor = .mainColor
                        labelEnd.text = "Screen Sharing session is over".localized()
                    }
                    if self.buttonDecline.isDescendant(of: self.view) {
                        self.buttonDecline.removeFromSuperview()
                    }
                    if self.buttonAccept.isDescendant(of: self.view) {
                        self.buttonAccept.removeFromSuperview()
                    }
                    terminate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.dismiss(animated: true, completion: nil)
                    }
                case CoreMessage_TMessageCode.SS_OFFHOOK:
                    //print("SS_OFFHOOK")
                    break
                case CoreMessage_TMessageCode.SS_RINGING:
                    //print("SS_RINGING")
                    break
                default:
                    //print("default")
                    break
                }
            }
        }
    }
    
    func sendInit(){
        API.initiateSS(sTitle: "", nQuality: 0)
    }
    
    func sendJoin(){
        API.joinSS(sBroadcasterID: user!.pin, ivRemoteView: imageSS)
    }
    
    func terminate(){
        API.terminateSS()
    }

}
