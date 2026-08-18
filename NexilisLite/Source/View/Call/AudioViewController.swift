//
//  AudioViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 02/09/21.
//

import UIKit

class AudioViewController: UIViewController {

    @IBOutlet weak var name: UILabel!
    
    @IBOutlet weak var status: UILabel!
    
    @IBOutlet weak var speaker: UIButton!
    
    @IBOutlet weak var mic: UIButton!
    
    @IBOutlet weak var end: UIButton!
    
    @IBOutlet weak var profile: UIImageView!
    
    var dataPerson: [[String: String?]] = []
    
    var isOutgoing: Bool = false
    
    var pin: String?
    
    var timer: Timer?
    
    override func viewDidLoad() {
        
        if isOutgoing {
            
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close(sender:)))
        }
        
        navigationController?.changeAppearance(clear: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onStatusCall(_:)), name: NSNotification.Name(rawValue: Nexilis.listenerStatusCall), object: nil)
        
        speaker.circle()
        speaker.setBackgroundColor(.white, for: .highlighted)
        speaker.addTarget(self, action: #selector(didSpeaker(sender:)), for: .touchUpInside)
        
        mic.circle()
        mic.setBackgroundColor(.white, for: .highlighted)
        mic.addTarget(self, action: #selector(didMic(sender:)), for: .touchUpInside)
        
        end.circle()
        end.setBackgroundColor(.white, for: .highlighted)
        end.addTarget(self, action: #selector(didEnd(sender:)), for: .touchUpInside)
        
        profile.circle()
        
        view.applyBlurEffect()
        view.backgroundColor = .blue
        
        if dataPerson.count > 0, let data = dataPerson.last, let pin = data["f_pin"], let pin = pin {
            self.pin = pin
            
            Database.shared.database?.inTransaction({ fmdb, rollback in
                do {
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select FIRST_NAME || ' ' || ifnull(LAST_NAME, ''), IMAGE_ID from BUDDY where F_PIN = '\(pin)'"), cursor.next() {
                        name.text = cursor.string(forColumnIndex: 0)?.trimmingCharacters(in: .whitespaces)
                        if let image = cursor.string(forColumnIndex: 1), !image.isEmpty {
                            profile.setImage(name: image)
                            profile.contentMode = .scaleAspectFill
                        }
                        
                        //
                        cursor.close()
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
            
            if isOutgoing {
//                Nexilis.shared.callManager.startCall(handle: pin)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.changeAppearance(clear: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.changeAppearance(clear: false)
        timer?.invalidate()
    }
    
    @objc func close(sender: Any) {
        
    }
    
    @objc func didSpeaker(sender: AnyObject?) {
        
    }
    
    @objc func didMic(sender: AnyObject?) {
        
    }
    
    @objc func didEnd(sender: AnyObject?) {
        //print("didEnd:\(pin)")
//        if let pin = self.pin, let call = Nexilis.shared.callManager.call(with: pin) {
//            Nexilis.shared.callManager.end(call: call)
//            if isOutgoing {
//                navigationController?.popViewController(animated: true)
//            } else {
//                navigationController?.dismiss(animated: true, completion: nil)
//            }
//        }
    }
    
    @objc func onStatusCall(_ notification: NSNotification) {
        if let data = notification.userInfo,
           let state = data["state"] as? Int,
           let message = data["message"] as? String
        {
            let r = message.split(separator: ",")
            if state == Nexilis.AUDIO_CALL_RINGING {
                DispatchQueue.main.async {
                    self.status.text = "Ringing..."
                }
            } else if state == Nexilis.AUDIO_CALL_OFFHOOK {
                DispatchQueue.main.async {
                    let connectDate = Date()
                    self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                        let format = Utils.callDurationFormatter.string(from: Date().timeIntervalSince(connectDate))
                        self.status.text = format
                    }
                    self.timer?.fire()
                }
            } else if state == Nexilis.AUDIO_CALL_END || state == Nexilis.BUSY {
                DispatchQueue.main.async {
                    if self.isOutgoing {
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        self.navigationController?.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
        
    }

    
}

extension UIView {
    
    func applyBlurEffect() {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(blurEffectView, at: 0)
    }
    
}

extension UIButton {
    
    func setBackgroundColor(_ color: UIColor, for forState: UIControl.State) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.setBackgroundImage(colorImage, for: forState)
    }
    
}

extension UIImageView {
    
    private static var urlStore = [String:String]()
    
    func setImage(name url: String, placeholderImage: UIImage? = nil) {
        let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
        UIImageView.urlStore[tmpAddress] = url
        
        guard !url.isEmpty else {
            if let image = placeholderImage {
                self.image = image
            }
            return
        }
        
        do {
            let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let file = documentDir.appendingPathComponent(url)
            if FileManager().fileExists(atPath: file.path) {
                self.image = UIImage(contentsOfFile: file.path)
                self.backgroundColor = .clear
            } else if FileEncryption.shared.isSecureExists(filename: url) {
                if var dataFile = try? FileEncryption.shared.readSecure(filename: url) {
                    let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: dataFile)
                    if dataDecrypt != nil {
                        dataFile = dataDecrypt!
                    }
                    self.image = UIImage(data: dataFile)
                    self.backgroundColor = .clear
                }
            } else {
                Download().startHTTP(forKey: url) { (name, progress) in
                    print ("masuk download \(progress)")
                    guard progress == 100 else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        if UIImageView.urlStore[tmpAddress] == url {
                            if var dataFile = try? FileEncryption.shared.readSecure(filename: url) {
                                let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: dataFile)
                                if dataDecrypt != nil {
                                    dataFile = dataDecrypt!
                                }
                                self.image = UIImage(data: dataFile)
                                self.backgroundColor = .clear
                            }
                        }
                    }
                }
            }
        } catch {}
    }
    
}

extension UINavigationController {
    func changeAppearance(clear: Bool) {
        if clear {
            navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationBar.backgroundColor = .clear
            navigationBar.shadowImage = UIImage()
            navigationBar.isTranslucent = true
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithTransparentBackground()
            navBarAppearance.backgroundColor = .clear
            navigationBar.standardAppearance = navBarAppearance
            navigationBar.scrollEdgeAppearance = navBarAppearance
        } else {
            navigationBar.setBackgroundImage(nil, for: .default)
            navigationBar.backgroundColor = .clear
            navigationBar.shadowImage = nil
            navigationBar.isTranslucent = false
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
            navigationBar.standardAppearance = navBarAppearance
            navigationBar.scrollEdgeAppearance = navBarAppearance
        }
    }
}

