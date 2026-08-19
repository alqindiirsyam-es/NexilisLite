//
//  Callback.swift
//  Runner
//
//  Created by Yayan Dwi on 15/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import UIKit
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
        if nCLMConStat != 0 {
            // The link is up: anything still sitting at status "1" never got its "2" and is
            // worth another try now.
            OutgoingThread.default.resendPending()
        }
    }
    
    func gpsStateChanged(nState: Int!) {
        
    }
    
    func sleepStateChanged(bState: Bool!) {
        
    }
    
    func callStateChanged(nState: Int!, sMessage: String!) -> Int {
//        print(nState,"/",sMessage)
        if nState == Nexilis.AUDIO_CALL_INCOMING || nState == Nexilis.VIDEO_CALL_INCOMING {
            if let delegate = Nexilis.shared.callDelegate {
                if !Nexilis.showLibraryNotification || Nexilis.callAPNActivated {
                    delegate.onStatusCall(state: nState, message: sMessage)
                } else {
                    delegate.onIncomingCall(state: nState, message: sMessage)
                }
            }
        } else {
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
        guard let packetId = sPacketID, let data = oData else {
            return
        }
        Nexilis.incomingData(packetId: packetId, data: data)
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
    var timerReloadData: Timer?
    private var disconnectWorkItem: DispatchWorkItem?
    
    private init() {}
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if path.status == .satisfied && API.nGetCLXConnState() != 0 {
                    // Cancel any pending "disconnected" work if connection is back
                    self.disconnectWorkItem?.cancel()
                    self.disconnectWorkItem = nil
                    
                    if !self.isConnected {
                        self.isConnected = true
                        self.handleConnected()
                    }
                } else {
                    // Debounce disconnection: wait 3s before declaring "offline"
                    self.scheduleDisconnectionCheck()
                }
            }
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
    
    private func scheduleDisconnectionCheck() {
        // Cancel any previous disconnection task
        disconnectWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            self.isConnected = false
            self.handleDisconnected()
        }
        
        disconnectWorkItem = workItem
        // Wait 3 seconds before declaring disconnected
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }
    
    private func handleDisconnected() {
        fromDisconnect = true
        DispatchQueue.main.async {
//            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
//            imageView.tintColor = .white
//            let banner = FloatingNotificationBanner(
//                title: "Check your connection".localized(),
//                subtitle: nil,
//                titleFont: UIFont.systemFont(ofSize: 16),
//                titleColor: nil,
//                titleTextAlign: .left,
//                subtitleFont: nil,
//                subtitleColor: nil,
//                subtitleTextAlign: nil,
//                leftView: imageView,
//                rightView: nil,
//                style: .danger,
//                colors: nil,
//                iconPosition: .center
//            )
//            banner.show()
            
            if Utils.getSecureFolderOffline() == "0" && Database.shared.database != nil {
                self.timerReloadData?.invalidate()
                self.timerReloadData = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                    Database.shared.database = nil
                    FileEncryption.shared.aesKey = nil
                    FileEncryption.shared.aesIV = nil
                    Database.recreateInstance()
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "disconnected_nexilis"), object: nil, userInfo: nil)
                    
                    if let navigationC = UIApplication.shared.visibleViewController as? UINavigationController {
                        if navigationC.viewControllers.last is EditorPersonal ||
                           navigationC.viewControllers.last is EditorGroup {
                            navigationC.popViewController(animated: true)
                        }
                    }
                }
            }
        }
    }
    
    private func handleConnected() {
        if fromDisconnect {
            fromDisconnect = false
            DispatchQueue.main.async {
                self.timerReloadData?.invalidate()
                self.timerReloadData = nil
                
//                let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
//                imageView.tintColor = .white
//                let banner = FloatingNotificationBanner(
//                    title: "You're Connected".localized(),
//                    subtitle: nil,
//                    titleFont: UIFont.systemFont(ofSize: 16),
//                    titleColor: nil,
//                    titleTextAlign: .left,
//                    subtitleFont: nil,
//                    subtitleColor: nil,
//                    subtitleTextAlign: nil,
//                    leftView: imageView,
//                    rightView: nil,
//                    style: .success,
//                    colors: nil,
//                    iconPosition: .center
//                )
//                banner.show()
            }
            if Database.shared.database == nil {
                Nexilis.getFeatureAccess()
            }
        }
        // Network path satisfied again - the socket may reconnect a moment later, but the
        // messages waiting to go out should not have to wait for that to be noticed.
        OutgoingThread.default.resendPending()
    }
}
