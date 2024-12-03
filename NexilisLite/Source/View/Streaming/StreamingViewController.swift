//
//  StreamingViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 13/09/21.
//

import UIKit
import nuSDKService

class StreamingViewController: UIViewController {
    
    @IBOutlet weak var cameraView: UIImageView!
    
    @IBOutlet weak var status: UILabel!
    
    @IBOutlet weak var camera: UIButton!
    
    var streamingTitle: String?
    
    var isInitiator: Bool = false
    
    var broadcastId: String?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Nexilis.shared.streamingDelagate = self
        
        navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        if  isInitiator, let streamingTitle = streamingTitle {
            API.initiateBC(sTitle: streamingTitle, nCamIdx: 1, nResIdx: 2, nVQuality: 2, ivLocalView: cameraView)
        } else if let broadcastId = broadcastId {
            camera.isHidden = true
            //
            API.joinBC(sBroadcasterID: broadcastId, ivRemoteView: cameraView)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        API.terminateBC(sBroadcasterID: nil)
    }
}

extension StreamingViewController: LiveStreamingDelegate {
    
    func onStartLS(state: Int, message: String) {
        //print("onStartLS: \(state):\(message)")
        if message.contains("Initiating") {
            DispatchQueue.main.async {
                self.cameraView.transform = CGAffineTransform.init(scaleX: 1.6, y: 1.6)
            }
        }
    }
    
    func onJoinLS(state: Int, message: String) {
        if state == Nexilis.AUDIO_CALL_OFFHOOK {
            let m = message.split(separator: ",")
            let from = String(m[0])
            let title = String(m[1])
            let camera = Int(m[2])
            let platform = Int(m[3])
            if platform == 1 { // Android
                DispatchQueue.main.async {
                    self.cameraView.transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: camera == 1 ? (CGFloat.pi * 3)/2 : (CGFloat.pi)/2)
                }
            }
        } else if state == Nexilis.AUDIO_CALL_RINGING {
            let m = message.split(separator: ",")
            let from = String(m[0])
            let title = String(m[1])
            let camera = Int(m[2])
            let platform = Int(m[3])
            if platform == 1 { // Android
                DispatchQueue.main.async {
                    self.cameraView.transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: camera == 1 ? (CGFloat.pi * 3)/2 : (CGFloat.pi)/2)
                }
            }
        } else if state == Nexilis.STREAMING_SEMINAR_ENDED {
            DispatchQueue.main.async {
                self.status.text = "Streaming ended".localized()
            }
        }
    }
    
}
