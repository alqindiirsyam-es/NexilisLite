//
//  Callback.swift
//  Runner
//
//  Created by Yayan Dwi on 15/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import nuSDKService
import Network
import NotificationBannerSwift

class Callback : CallBack {
    var sID: String = "Callback"
    
    func connectionStateChanged(sUserID: String!, sDeviceID: String!, bConState: Bool!, nConType: Int!, nConSubType: Int!, nCLMConStat: UInt8!) {
        //print(sUserID, "/", sDeviceID, "/", bConState, "/", nConType, "/", nConSubType, "/", nCLMConStat)
        if let dispatch = Nexilis.dispatch, bConState {
            dispatch.leave()
        }
        if let delegate = Nexilis.shared.connectionDelegate {
            delegate.connectionStateChanged(userId: sUserID, deviceId: sDeviceID, state: bConState)
        }
        InquiryThread.default.set(wait: nCLMConStat == 0)
        OutgoingThread.default.set(wait: nCLMConStat == 0)
    }
    
    func gpsStateChanged(nState: Int!) {
        
    }
    
    func sleepStateChanged(bState: Bool!) {
        
    }
    
    func callStateChanged(nState: Int!, sMessage: String!) -> Int {
        //print(nState,"/",sMessage)
        if nState == Nexilis.AUDIO_CALL_INCOMING || nState == Nexilis.VIDEO_CALL_INCOMING {
            if let delegate = Nexilis.shared.callDelegate {
                if !Nexilis.showLibraryNotification {
                    delegate.onStatusCall(state: nState, message: sMessage)
                } else {
                    delegate.onIncomingCall(state: nState, message: sMessage)
                }
            }
        } else {
//            if nstate == Nexilis.AUDIO_CALL_END {
//                let pin = sMessage.split(separator: ",")[0]
//                if let call = Palio.shared.callManager.call(with: String(pin)), !call.hasVideo, !call.hasEnded {
//                    call.reconnectingCall()
//                    return 1
//                }
//            }
            if let delegate = Nexilis.shared.callDelegate {
                delegate.onStatusCall(state: nState, message: sMessage)
            }
        }
        
        return 1
    }
    
    func bcastStateChanged(nState: Int!, sMessage: String!) -> Int {
        //print("LS CALLBACK ",nState,"/",sMessage)
        if let delegate = Nexilis.shared.streamingDelagate {
            delegate.onStartLS(state: nState, message: sMessage)
        }
        if let delegate = Nexilis.shared.streamingDelagate {
            delegate.onJoinLS(state: nState, message: sMessage)
        }
        if let delegate = Nexilis.shared.seminarDelegate {
            delegate.onStartSeminar(state: nState, message: sMessage)
        }
        if let delegate = Nexilis.shared.seminarDelegate {
            delegate.onJoinSeminar(state: nState, message: sMessage)
        }
        return 1
    }
    
    func sshareStateChanged(nState: Int!, sMessage: String!) -> Int {
        //print("Screen sharing state: ",nState,"/",sMessage)
        switch nState {
            case 0:
                if (sMessage.starts(with: "Initiating")){
                    if let delegate = Nexilis.shared.screenSharingDelegate {
                        delegate.onStartScreenSharing(state: nState, message: sMessage)
                    }
                }
            case 12:
                if let delegate = Nexilis.shared.screenSharingDelegate {
                    delegate.onStartScreenSharing(state: nState, message: sMessage)
                }
            case 22:
                if let delegate = Nexilis.shared.screenSharingDelegate {
                    delegate.onJoinScreenSharing(state: nState, message: sMessage)
                }
            case 88:
                if let delegate = Nexilis.shared.screenSharingDelegate {
                    delegate.onStartScreenSharing(state: nState, message: sMessage)
                }
                if let delegate = Nexilis.shared.screenSharingDelegate {
                    delegate.onJoinScreenSharing(state: nState, message: sMessage)
                }
            default:
                break
        }
        return 1
    }
    
    func incomingData(sPacketID: String!, oData: AnyObject!) throws {
        Nexilis.incomingData(packetId: sPacketID!, data: oData!)
    }
    
    func lateResponse(sPacketID: String!, sResponse: String!) throws {
        
    }
    
    func asycnACKReceived(sPacketID: String!) throws {
        //print("asycnACKReceived: \(sPacketID)")
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    OutgoingThread.default.delOutgoing(fmdb: fmdb, packageId: sPacketID)
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        }
    }
    
    func locationUpdated(lTime: Int64!, sLocationInfo: String!) {
        
    }
    
    func resetDB() {
        
    }
    
}

class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private var isMonitoring = false
    var isConnected: Bool = false
    var fromDisconnect = false
    
    private init() {}
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            self.canAccessGoogle(completion: { [self] connected in
                InquiryThread.default.set(wait: !connected)
                OutgoingThread.default.set(wait: !connected)
                if !connected {
                    fromDisconnect = true
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
                if connected && fromDisconnect {
                    fromDisconnect = false
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "You're Connected".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            })
        }
        
        let queue = DispatchQueue.global(qos: .background)
        monitor.start(queue: queue)
        isMonitoring = true
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        monitor.cancel()
        isMonitoring = false
    }
    
    func canAccessGoogle(completion: @escaping (Bool) -> Void) {
        guard isConnected, let url = URL(string: "https://www.google.com") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }
        task.resume()
    }
}
