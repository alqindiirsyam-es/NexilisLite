//
//  WhiteboardViewController.swift
//  NexilisLite
//
//  Created by Kevin Maulana on 31/03/22.
//

// Rn
// onalphachanged

import UIKit

class WhiteboardViewController: UIViewController, WhiteboardDelegate {
    
    func draw(x: String, y: String, w: String, h: String, fc: String, sw: String, xo: String, yo: String, data: String) {
        wb!.draw(x: x, y: y, w: w, h: h, fc: fc, sw: sw, xo: xo, yo: yo, data: data)
    }
    
    @objc func clear(){
        wb?.clear()
    }
    
    var wbc : WhiteboardCanvas?
    var wbcConstraintTop = NSLayoutConstraint()
    var wbcConstraintBottom = NSLayoutConstraint()
    var wbcConstraintLeft = NSLayoutConstraint()
    var wbcConstraintRight = NSLayoutConstraint()
    var wb : Whiteboard?
    var roomId = ""
    var destinations = [String]()
    var incoming = false
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
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wb = Whiteboard(delegated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if fromContact != nil {
            addBackgroundIncoming()
            addProfileNameCalling()
            Calling()
            addToolbar()
        } else {
            initWhiteboard()
        }
        self.title = "Whiteboard".localized()
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(wbSession(notification:)), name: NSNotification.Name(rawValue: "wbSession"), object: nil)
//        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close".localized(), style: .plain, target: self, action: #selector(close))
//        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear".localized(), style: .plain,target: self, action: #selector(clear))
        

        // Do any additional setup after loading the view.
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
            labelIncomingOutgoing.text = "Waiting for answer".localized() + "..."
            _ = Nexilis.write(message: CoreMessage_TMessageBank.wbCreate(l_pin: user!.pin))
        } else {
            labelIncomingOutgoing.text = "Incoming Whiteboard".localized() + "..."
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
        let alert = LibAlertController(title: "End Whiteboard Session".localized(), message: "Are you sure you want to end whiteboard session?".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: {(_) in
            if self.fromContact == 0 {
                _ = Nexilis.write(message: CoreMessage_TMessageBank.wbEnded(l_pin: self.user!.pin))
            } else {
                _ = Nexilis.write(message: CoreMessage_TMessageBank.wbReject(l_pin: self.user!.pin))
            }
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func didTapAcceptCallButton() {
        _ = Nexilis.write(message: CoreMessage_TMessageBank.wbAccept(l_pin: user!.pin))
        self.myImage.removeFromSuperview()
        self.name.removeFromSuperview()
        self.profileImage.removeFromSuperview()
        self.labelIncomingOutgoing.removeFromSuperview()
        self.buttonDecline.removeFromSuperview()
        self.buttonAccept.removeFromSuperview()
        NSLayoutConstraint.deactivate([
            self.constraintLeadingButtonDecline,
            self.constraintBottomButtonDecline
        ])
        self.initWhiteboard()
        SecureUserDefaults.shared.set("\(user!.pin),\(User.getMyPin() ?? "")", forKey: "wb_vc")
    }
    
    @objc func wbSession(notification: NSNotification) {
        DispatchQueue.main.async { [self] in
            let data:[AnyHashable : Any] = notification.userInfo!
            if let message = data["message"] as? TMessage {
                let status = message.getBody(key: CoreMessage_TMessageKey.STATUS, default_value: "")
                switch (Int(status)) {
                case CoreMessage_TMessageCode.WB_ACCEPT_INCOMING:
                    //print("WB_ACCEPT_INCOMING")
                    let f_pin = message.getBody(key: CoreMessage_TMessageKey.F_USER_ID, default_value: "")
                    _ = Nexilis.write(message: CoreMessage_TMessageBank.wbOffhook(l_pin: f_pin))
                    DispatchQueue.main.async {
                        self.myImage.removeFromSuperview()
                        self.name.removeFromSuperview()
                        self.profileImage.removeFromSuperview()
                        self.labelIncomingOutgoing.removeFromSuperview()
                        self.buttonDecline.removeFromSuperview()
                        NSLayoutConstraint.deactivate([
                            self.constraintLeadingButtonDecline,
                            self.constraintBottomButtonDecline
                        ])
                        self.initWhiteboard()
                        let tid = CoreMessage_TMessageUtil.getTID()
                        self.roomId = "\(f_pin)WB\(tid)"
                        self.destinations = [f_pin]
                        self.sendInit()
                        SecureUserDefaults.shared.set("\(User.getMyPin() ?? ""),\(f_pin)", forKey: "wb_vc")
                    }
                case CoreMessage_TMessageCode.WB_REJECT_INCOMING,CoreMessage_TMessageCode.WB_END:
                    //print("WB_REJECT_INCOMING \(status)")
                    if self.labelIncomingOutgoing.isDescendant(of: self.view) {
                        self.labelIncomingOutgoing.text = "WhiteBoard session is over".localized()
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
                        labelEnd.text = "WhiteBoard session is over".localized()
                    }
                    if self.buttonDecline.isDescendant(of: self.view) {
                        self.buttonDecline.removeFromSuperview()
                    }
                    if self.buttonAccept.isDescendant(of: self.view) {
                        self.buttonAccept.removeFromSuperview()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.dismiss(animated: true, completion: nil)
                    }
                case CoreMessage_TMessageCode.WB_OFFHOOK:
                    //print("WB_OFFHOOK")
                    break
                case CoreMessage_TMessageCode.WB_RINGING:
                    //print("WB_RINGING")
                    break
                default:
                    //print("default")
                    break
                }
            }
        }
    }
    
    func initWhiteboard(){
        _ = self.view.frame.width * 20.0 / 9.0
        let rect = CGRect(x: 0.0, y: 0.0, width: self.view.frame.width, height: self.view.frame.height)
        wbc = WhiteboardCanvas(frame: rect)
//        wbc?.translatesAutoresizingMaskIntoConstraints = false
//        wbcConstraintTop = (wbc?.topAnchor.constraint(equalTo: self.view.topAnchor))!
//        wbcConstraintBottom = (wbc?.bottomAnchor.constraint(equalTo: self.view.bottomAnchor))!
//        wbcConstraintRight = (wbc?.rightAnchor.constraint(equalTo: self.view.rightAnchor))!
//        wbcConstraintLeft = (wbc?.leftAnchor.constraint(equalTo: self.view.leftAnchor))!
//        NSLayoutConstraint.activate([wbcConstraintTop, wbcConstraintBottom, wbcConstraintLeft, wbcConstraintRight])
        wb?.canvas = wbc
        self.view.addSubview(wbc!)
        Nexilis.setWhiteboardDelegate(delegate: self)
        
    }
    
    func sendInit(){
        let d = destinations.joined(separator: ",")
        //print("KOCAK \(d)")
//            roomId = "\(me)\(tid)"
        wb?.setRoomId(roomId: roomId)
        wb!.sendInit(destinations: d)
        
    }
    
    func sendJoin(){
        wb?.setRoomId(roomId: roomId)
        wb!.sendJoin()
    }
    
    var close : (() -> Void)?
    
    func terminate(){
        wb?.sendTerminate()
        Nexilis.setWhiteboardDelegate(delegate: nil)
        close?()
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        if fromContact != nil {
            didTapDeclineCallButton(sender: 0)
            return
        }
        close?()
    }
    
    @IBAction func didTapClear(_ sender: Any) {
        wb?.clear()
        wb?.sendClear()
    }
    
    
    @IBAction func onAlphaChanged(_ sender: UISlider) {
        let alp = ((sender.value / (100.0 / 25.0)) + (100.0 - 25.0))  / 100.0
        view.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: CGFloat(alp))
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension WhiteboardViewController : WhiteboardReceiver {
    
    func incomingWB(roomId: String) {
        self.roomId = roomId
        self.sendJoin()
    }
    
    func cancel(roomId: String) {
        
    }
    
}
