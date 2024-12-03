//
//  VideoViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 07/09/21.
//

import UIKit
import nuSDKService
import AVFoundation

class VideoViewController: UIViewController {
    
    @IBOutlet var zoomView: UIImageView!
    @IBOutlet var cameraView: UIImageView!
    @IBOutlet var buttonSwitchCamera: UIButton!
    @IBOutlet var buttonEndCall: UIButton!
    @IBOutlet var viewButtonDeclineAccept: UIView!
    @IBOutlet var buttonDeclineCall: UIButton!
    @IBOutlet var buttonAcceptCall: UIButton!
    @IBOutlet var buttonMuteVoice: UIButton!
    @IBOutlet var buttonSpeaker: UIButton!
    @IBOutlet var labelStatusCall: UILabel!
    @IBOutlet var imageProfile: UIImageView!
    @IBOutlet var listRemoteView: UITableView!
    
    var dataPerson: [[String: String?]] = []
    var isInisiator = true
    var isSpeaker = false
    var isMute = false
    var listRemoteViewFix: [UIImageView] = []
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view.backgroundColor = nil
        self.navigationController?.navigationBar.titleTextAttributes = nil
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = nil
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    func setStyleAppBar() {
        DispatchQueue.main.async {
            self.title = "Video Call"
            self.navigationController?.navigationBar.tintColor = UIColor.white
            self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            self.navigationController?.navigationBar.shadowImage = UIImage()
            self.navigationController?.navigationBar.isTranslucent = true
            self.navigationController?.view.backgroundColor = .clear
            let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
            self.navigationController?.navigationBar.titleTextAttributes = textAttributes
            self.labelStatusCall.isHidden = true
            self.imageProfile.isHidden = true
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Nexilis.listenerStatusCall), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "afterAddParticipantVideo"), object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listRemoteView.delegate = self
        listRemoteView.dataSource = self
        title = dataPerson[0]["name"]!
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        imageProfile.circle()
        let pictureImage = dataPerson[0]["picture"]!
        if (pictureImage != "" && pictureImage != nil) {
            imageProfile.setImage(name: pictureImage!)
            imageProfile.contentMode = .scaleAspectFill
        }
        showButton(isShow: false)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationItem.setHidesBackButton(true, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(self.addCallParticipant(_:)), name: NSNotification.Name(rawValue: "afterAddParticipantVideo"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onStatusCall(_:)), name: NSNotification.Name(rawValue: Nexilis.listenerStatusCall), object: nil)
        if (dataPerson.count > 0) {
            if (isInisiator) {
                viewButtonDeclineAccept.isHidden = true
                buttonAcceptCall.isHidden = true
                buttonDeclineCall.isHidden = true
                buttonEndCall.circle()
                buttonEndCall.addTarget(self, action: #selector(didTapEndCallButton(sender:)), for: .touchUpInside)
                cameraView.makeRoundedView(radius: 8)
                API.initiateCCall(sParty: dataPerson[0]["f_pin"]!, nCamIdx: 1, nResIdx: 2, nVQuality: 2, ivRemoteView: listRemoteViewFix, ivLocalView: cameraView, ivRemoteZ: zoomView)
            } else {
                labelStatusCall.text = "Incoming Video Call"
                buttonEndCall.isHidden = true
                self.viewButtonDeclineAccept.clipsToBounds = true
                viewButtonDeclineAccept.layer.cornerRadius = 15
                viewButtonDeclineAccept.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                buttonDeclineCall.layer.cornerRadius = 5.0
                buttonAcceptCall.layer.cornerRadius = 5.0
                buttonDeclineCall.addTarget(self, action: #selector(didTapDeclineCallButton(sender:)), for: .touchUpInside)
                buttonAcceptCall.addTarget(self, action: #selector(didTapAcceptCallButton(sender:)), for: .touchUpInside)
            }
        }
    }
    
    @objc func didTapAddParticipantButton(sender: AnyObject){
        if let contactViewController = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactSID") as? ContactCallViewController {
            contactViewController.isAddParticipantVideo = true
            contactViewController.connectedCall = dataPerson
            show(contactViewController, sender: nil)
        }
    }
    
    @objc func didTapEndCallButton(sender: AnyObject){
        setSpeaker(isSpeaker: false)
        showButton(isShow: false)
        endAllCall()
        if isInisiator {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func didTapSpeakerButton(sender: AnyObject){
        setSpeaker(isSpeaker: !(self.isSpeaker))
    }
    
    @objc func didTapSwitchCameraButton(sender: AnyObject){
        API.changeCameraParam(nCameraIdx: 1, nResolutionIndex: 1, nQuality: 1)
    }
    
    @objc func didTapDeclineCallButton(sender: AnyObject){
        showButton(isShow: false)
        endAllCall()
        if isInisiator {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func didTapAcceptCallButton(sender: AnyObject){
        cameraView.makeRoundedView(radius: 8)
        API.receiveCCall(sParty: dataPerson[0]["f_pin"]!, nCamIdx: 1, nResIdx: 2, nVQuality: 2, ivRemoteView: listRemoteViewFix, ivLocalView: cameraView,ivRemoteZ: zoomView)
    }
    
    @objc func onStatusCall(_ notification: NSNotification) {
        let data = notification.userInfo
        let state = (data?["state"] ?? 0) as! Int
        let message = (data?["message"] ?? "") as! String
        var remoteChannel = [String:String]()
        let arrayMessage = message.split(separator: ",")
        //        let me = User.getMyPin()!
        if(state == Nexilis.VIDEO_CALL_ZOOM){
            DispatchQueue.main.async {
                self.zoomView.transform   = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: (CGFloat.pi * 3)/2)
            }
        }
        else if (state == Nexilis.VIDEO_CAMERA_PARAMS_CHANED){
            let channel = arrayMessage[arrayMessage.count - 1]
            if(remoteChannel[String(channel)] != "2"){
                DispatchQueue.main.async {
                    if(arrayMessage[arrayMessage.count - 2] == "0"){ // back camera
                        self.zoomView.transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: (CGFloat.pi)/2)
                    }
                    else { // front camera
                        self.zoomView.transform = CGAffineTransform.init(scaleX: -2, y: 2).rotated(by: (CGFloat.pi * 3)/2)
                    }
                }
            }
        }
        else if (state == Nexilis.VIDEO_CALL_OFFHOOK){
            let channel = arrayMessage[3]
            remoteChannel[String(channel)] = String(arrayMessage[5])
            if (arrayMessage[5] == "2") {
                DispatchQueue.main.async {
                    self.zoomView.transform   = CGAffineTransform.init(scaleX: -2, y: 2).rotated(by: (CGFloat.pi)/2)
                    self.zoomView.contentMode = .scaleAspectFit
                    if (self.dataPerson.count > 1) {
                        if (self.dataPerson.count == 2) {
                            self.listRemoteViewFix[0].transform = CGAffineTransform.init(scaleX: -2, y: 2).rotated(by: (CGFloat.pi * 5)/2)
                            self.listRemoteViewFix[0].isHidden = false
                        }
                        let indexPerson = self.dataPerson.firstIndex(where: {$0["f_pin"]!! == arrayMessage[1]})
                        if (indexPerson != -1) {
                            self.listRemoteViewFix[indexPerson!].transform = CGAffineTransform.init(scaleX: -2, y: 2).rotated(by: (CGFloat.pi * 5)/2)
                        }
                    }
                }
            }
            else {
                DispatchQueue.main.async {
                    self.zoomView.transform   = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: (CGFloat.pi * 3)/2)
                    self.zoomView.contentMode = .scaleAspectFit
                    if (self.dataPerson.count > 1) {
                        if (self.dataPerson.count == 2) {
                            self.listRemoteViewFix[0].transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: (CGFloat.pi)/2)
                        }
                        let indexPerson = self.dataPerson.firstIndex(where: {$0["f_pin"]!! == arrayMessage[1]})
                        if (indexPerson != -1) {
                            self.listRemoteViewFix[indexPerson!].transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: (CGFloat.pi)/2)
                        }
                    }
                }
            }
            if (!self.isSpeaker) {
                setSpeaker(isSpeaker: true)
            }
            showButton(isShow: true)
            setStyleAppBar()
        } else if (state == Nexilis.VIDEO_CALL_END || state == Nexilis.AUDIO_CALL_END) {
            DispatchQueue.main.async {
                if (self.dataPerson.count == 1) {
                    //                let channel = arrayMessage[1]
                    //                if(Int(arrayMessage[2])! == 2 && !self.listRemoteViewFix.isEmpty) {
                    //                    self.listRemoteViewFix[0].isHidden = true
                    //                    self.listRemoteViewFix[1].isHidden = true
                    //                } else if(!self.listRemoteViewFix.isEmpty){
                    //                    self.listRemoteViewFix[Int(channel)!].isHidden = true
                    //                }
                    if (self.labelStatusCall.superview == nil) {
                        self.labelStatusCall.isHidden = false
                        self.labelStatusCall.textColor = UIColor.white
                    }
                    self.labelStatusCall.text = "Video call is over"
                    self.buttonEndCall.isHidden = true
                    self.setSpeaker(isSpeaker: false)
                    self.showButton(isShow: false)
                    if (!self.isInisiator && !self.isSpeaker) {
                        self.viewButtonDeclineAccept.isHidden = true
                    }
                } else {
                    let indexPerson = self.dataPerson.firstIndex(where: {$0["f_pin"]!! == arrayMessage[0]})
                    if (self.dataPerson.count == 2) {
                        let cell0 = self.listRemoteView.cellForRow(at:  IndexPath(row: 0, section: 0)) as! CustomCellRemoteView
                        let cell1 = self.listRemoteView.cellForRow(at:  IndexPath(row: 0, section: 1)) as! CustomCellRemoteView
                        cell0.isHidden = true
                        cell1.isHidden = true
                    } else {
                        let indexPath = IndexPath(row: 0, section: indexPerson!)
                        let cell = self.listRemoteView.cellForRow(at: indexPath) as! CustomCellRemoteView
                        cell.isHidden = true
                    }
                    self.dataPerson.remove(at: indexPerson!)
                }
            }
            if (self.dataPerson.count == 1) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.endAllCall()
                    if self.isInisiator {
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        } else if (state == Nexilis.OFFLINE) {
            DispatchQueue.main.async {
                self.buttonEndCall.isHidden = true
                self.labelStatusCall.text = "Offline"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.endAllCall()
                if self.isInisiator {
                    self.navigationController?.popViewController(animated: true)
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        } else if (state == Nexilis.BUSY) {
            DispatchQueue.main.async {
                if (self.dataPerson.count == 1) {
                    self.buttonEndCall.isHidden = true
                    self.labelStatusCall.text = "Busy"
                } else {
                    let indexPerson = self.dataPerson.firstIndex(where: {$0["f_pin"]!! == arrayMessage[0]})
                    if (self.dataPerson.count == 2) {
                        let cell0 = self.listRemoteView.cellForRow(at:  IndexPath(row: 0, section: 0)) as! CustomCellRemoteView
                        let cell1 = self.listRemoteView.cellForRow(at:  IndexPath(row: 0, section: 1)) as! CustomCellRemoteView
                        cell0.isHidden = true
                        cell1.isHidden = true
                    } else {
                        let indexPath = IndexPath(row: 0, section: indexPerson!)
                        let cell = self.listRemoteView.cellForRow(at: indexPath) as! CustomCellRemoteView
                        cell.isHidden = true
                    }
                    self.dataPerson.remove(at: indexPerson!)
                }
            }
            if (self.dataPerson.count == 1) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.endAllCall()
                    if self.isInisiator {
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        } else if (state == Nexilis.VIDEO_CALL_RINGING) {
            DispatchQueue.main.async {
                if (self.dataPerson.count > 1) {
                    if (self.dataPerson.count == 2) {
                        let indexPath = IndexPath(row: 0, section: 0)
                        let cell = self.listRemoteView.cellForRow(at: indexPath) as! CustomCellRemoteView
                        cell.containerViewImage.isHidden = false
                    }
                    let indexPath = IndexPath(row: 0, section: self.dataPerson.count - 1)
                    let cell = self.listRemoteView.cellForRow(at: indexPath) as! CustomCellRemoteView
                    cell.containerViewImage.isHidden = false
                    let pictureImage = self.dataPerson[self.dataPerson.count - 1]["picture"]!
                    if (pictureImage != "" && pictureImage != nil) {
                        cell.remoteView.setImage(name: pictureImage!)
                        cell.remoteView.contentMode = .scaleAspectFill
                    } else {
                        cell.remoteView.image = UIImage(systemName: "person")
                        cell.remoteView.backgroundColor = UIColor.systemGray6
                        cell.remoteView.contentMode = .scaleAspectFill
                    }
                    cell.labelRemoteView.text = self.dataPerson[self.dataPerson.count - 1]["name"]!
                }
            }
        }
    }
    
    func setSpeaker(isSpeaker: Bool) {
//        DispatchQueue.main.async {
//            if (isSpeaker) {
//                self.buttonSpeaker.backgroundColor = UIColor.systemGray4
//                
//            } else {
//                self.buttonSpeaker.backgroundColor = UIColor.systemBlue
//            }
//            self.isSpeaker = isSpeaker
//        }
//        let session = AVAudioSession.sharedInstance()
//        var _: Error?
//        if isSpeaker {
//            try? session.setCategory(AVAudioSession.Category.playAndRecord)
//            try? session.setMode(AVAudioSession.Mode.voiceChat)
//            try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
//        } else {
//            try? session.setCategory(.ambient)
//            try? session.setMode(.default)
//            try? session.overrideOutputAudioPort(.none)
//        }
//        try? session.setActive(true)
    }
    
    func setMicrophone(isMute: Bool) {
        if (isMute) {
            DispatchQueue.main.async {
                self.buttonSpeaker.backgroundColor = UIColor.systemBlue
            }
        } else {
            DispatchQueue.main.async {
                self.buttonMuteVoice.backgroundColor = UIColor.systemGray4
            }
        }
    }
    
    func showButton(isShow: Bool) {
        if (isShow) {
            DispatchQueue.main.async {
                self.buttonSwitchCamera.isHidden = false
                self.buttonMuteVoice.isHidden = false
                self.buttonSpeaker.isHidden = false
                self.buttonSwitchCamera.circle()
                self.buttonMuteVoice.circle()
                self.buttonSpeaker.circle()
                self.buttonSpeaker.addTarget(self, action: #selector(self.didTapSpeakerButton(sender:)), for: .touchUpInside)
                self.buttonSwitchCamera.addTarget(self, action: #selector(self.didTapSwitchCameraButton(sender:)), for: .touchUpInside)
                let addParticipantImage = UIImage(systemName: "person.crop.circle.badge.plus")?.flipHorizontally()
                let buttonAddParticipant = UIBarButtonItem(image: addParticipantImage,  style: .plain, target: self, action: #selector(self.didTapAddParticipantButton(sender:)))
                self.navigationItem.rightBarButtonItem = buttonAddParticipant
                if (!self.isInisiator) {
                    self.viewButtonDeclineAccept.isHidden = true
                    self.buttonEndCall.isHidden = false
                    self.buttonEndCall.circle()
                    self.buttonEndCall.addTarget(self, action: #selector(self.didTapEndCallButton(sender:)), for: .touchUpInside)
                }
            }
        } else {
            DispatchQueue.main.async {
                self.buttonSwitchCamera.isHidden = true
                self.buttonMuteVoice.isHidden = true
                self.buttonSpeaker.isHidden = true
            }
        }
    }
    
    func endAllCall() {
        API.terminateCall(sParty: nil)
        cameraView = nil
        zoomView = nil
        listRemoteViewFix.removeAll()
    }
    
    @objc func addCallParticipant(_ notification: NSNotification) {
        let data = notification.userInfo
        DispatchQueue.main.async {
            var row: [String: String?] = [:]
            row["f_pin"] = data?["f_pin"] as? String
            row["name"] = data?["name"] as? String
            row["picture"] = data?["picture"] as? String
            row["isOfficial"] = data?["isOfficial"] as? String
            row["deviceId"] = data?["deviceId"] as? String
            row["isOffline"] = data?["isOffline"] as? String
            row["user_type"] = data?["user_type"] as? String
            self.dataPerson.append(row)
        }
        cameraView.makeRoundedView(radius: 8)
        API.initiateCCall(sParty: data?["f_pin"] as? String, nCamIdx: 1, nResIdx: 2, nVQuality: 2, ivRemoteView: listRemoteViewFix, ivLocalView: cameraView,ivRemoteZ: zoomView)
    }
    
}

extension UIImage {
    func flipHorizontally() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        context.translateBy(x: self.size.width/2, y: self.size.height/2)
        context.scaleBy(x: -1.0, y: 1.0)
        context.translateBy(x: -self.size.width/2, y: -self.size.height/2)
        
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

extension VideoViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "remoteViewCell", for: indexPath ) as! CustomCellRemoteView
        if (listRemoteViewFix.count < 5) {
            cell.containerViewImage.makeRoundedView(radius: 8)
            cell.remoteView.makeRoundedView(radius: 8)
            cell.containerLabel.makeRoundedView(radius: 5)
            if(indexPath.section == 0) {
                cell.labelRemoteView.text = self.dataPerson[indexPath.section]["name"] ?? ""
                let pictureImage = self.dataPerson[indexPath.section]["picture"]!
                if (pictureImage != "" && pictureImage != nil) {
                    cell.remoteView.setImage(name: pictureImage!)
                    cell.remoteView.contentMode = .scaleAspectFill
                } else {
                    cell.remoteView.image = UIImage(systemName: "person")
                    cell.remoteView.backgroundColor = UIColor.systemGray6
                    cell.remoteView.contentMode = .scaleAspectFill
                }
            }
            cell.containerViewImage.isHidden = true
            listRemoteViewFix.append(cell.remoteView)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
}

extension UIViewController{
    
    func showToast(message : String, seconds: Double){
        let alert = LibAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.view.backgroundColor = .black
        alert.view.alpha = 0.5
        alert.view.layer.cornerRadius = 15
        self.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
            alert.dismiss(animated: true)
        }
    }
}

extension UIView {
    func makeRoundedView(radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.clipsToBounds = true
        self.layer.masksToBounds = true
    }
}

class CustomCellRemoteView: UITableViewCell {
    @IBOutlet var remoteView: UIImageView!
    @IBOutlet var containerViewImage: UIView!
    @IBOutlet var labelRemoteView: UILabel!
    @IBOutlet var containerLabel: UIView!
}
