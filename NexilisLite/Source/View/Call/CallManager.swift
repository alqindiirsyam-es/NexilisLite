//
//  CallManager.swift
//  FloatingButtonApp
//
//  Created by Yayan Dwi on 10/08/21.
//

import Foundation
import CallKit
import nuSDKService
import AVFAudio
import UIKit
import Combine

public class CallManager: NSObject, ObservableObject {
    
    public static let shared = CallManager()
    private var activeCalls: [UUID: CallInfo] = [:]
        
    private let provider: CXProvider
    private let callController = CXCallController()
    
    override init() {
        let providerConfiguration = CXProviderConfiguration(localizedName: Bundle.main.infoDictionary?["CFBundleName"] as! String)
        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        if let logoImage = UIImage(named: "pb_ball", in: Bundle.resourceBundle(for: Nexilis.self), with: nil) {
            if let imageData = logoImage.pngData() {
                providerConfiguration.iconTemplateImageData = imageData
            }
        }
        
        
        provider = CXProvider(configuration: providerConfiguration)
        super.init()
        self.provider.setDelegate(self, queue: nil)
    }
    
    func startCall(uuid: UUID, callerName: String, callerId: String, isVideo: Bool) {
        let handle = CXHandle(type: .generic, value: callerId)
        let startCallAction = CXStartCallAction(call: uuid, handle: handle)
        startCallAction.isVideo = isVideo
        
        let transaction = CXTransaction(action: startCallAction)
        
        callController.request(transaction) { error in
            if let error = error {
                print("Error starting call: \(error.localizedDescription)")
            } else {
                print("Call started successfully")
            }
        }
    }
    
    public func reportIncomingCall(uuid: UUID, callerName: String, callerId: String, isVideo: Bool) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: callerId)
        update.localizedCallerName = callerName
        update.hasVideo = isVideo
        activeCalls[uuid] = CallInfo(uuid: uuid, callerId: callerId, callerName: callerName, isVideo: isVideo, isAccepted: false)

        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error = error {
                print("Error reporting incoming call: \(error.localizedDescription)")
            }
        }
    }
    
    public func endCall(uuid: UUID, completion: @escaping () -> ()) {
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)

        callController.request(transaction) { error in
            if let error = error {
                print("Failed to end call: \(error.localizedDescription)")
            } else {
                completion()
            }
        }
    }
    
}

extension CallManager: CXProviderDelegate {
    public func providerDidReset(_ provider: CXProvider) {
    }
    
    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        let uuid = action.callUUID
        if let callInfo = activeCalls[uuid] {
            self.activeCalls[uuid]?.isAccepted = true
            if callInfo.isVideo {
                let videoController = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "videoVCQmera") as! QmeraVideoViewController
                videoController.fPin = callInfo.callerId
                videoController.isInisiator = false
                videoController.autoAcceptAPN = true
                let navigationController = CustomNavigationController(rootViewController: videoController)
                navigationController.modalPresentationStyle = .fullScreen
                if UIApplication.shared.visibleViewController is UIAlertController {
                    let vc = UIApplication.shared.visibleViewController as! UIAlertController
                    vc.dismiss(animated: true, completion: {
                        if UIApplication.shared.visibleViewController?.navigationController != nil {
                            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                        } else {
                            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                        }
                    })
                    return
                }
                if UIApplication.shared.visibleViewController?.navigationController != nil {
                    UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                } else {
                    UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                }
            } else {
                let controller = QmeraAudioViewController()
                controller.isOutgoing = false
                controller.user = User.getData(pin: callInfo.callerId)
                controller.autoAcceptAPN = true
                controller.modalPresentationStyle = .overCurrentContext
                if UIApplication.shared.visibleViewController is UIAlertController {
                    let vc = UIApplication.shared.visibleViewController as! UIAlertController
                    vc.dismiss(animated: true, completion: {
                        if UIApplication.shared.visibleViewController?.navigationController != nil {
                            UIApplication.shared.visibleViewController?.navigationController?.present(controller, animated: true, completion: nil)
                        } else {
                            UIApplication.shared.visibleViewController?.present(controller, animated: true, completion: nil)
                        }
                    })
                    return
                }
                if UIApplication.shared.visibleViewController?.navigationController != nil {
                    UIApplication.shared.visibleViewController?.navigationController?.present(controller, animated: true, completion: nil)
                } else {
                    UIApplication.shared.visibleViewController?.present(controller, animated: true, completion: nil)
                }
            }
        }
        action.fulfill()
    }
    
    private func rootWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first{$0.activationState == .foregroundActive}
    }
    
    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        if Nexilis.callAPNActivated {
            let uuid = action.callUUID
            if let callInfo = activeCalls[uuid] {
                if !callInfo.isAccepted {
                    DispatchQueue.global().async {
                        do {
                            if API.nGetCLXConnState() == 0 {
                                let id = Utils.getConnectionID()
                                try API.initConnection(sAPIK: Nexilis.sAPIKey, cbiI: Callback(), sTCPAddr: Nexilis.ADDRESS, nTCPPort: Nexilis.PORT, sUserID: id, sStartWH: "09:00")
                                while API.nGetCLXConnState() == 0 {
                                    Thread.sleep(forTimeInterval: 1)
                                }
                                sendCancel()
                            } else {
                                sendCancel()
                            }
                            func sendCancel() {
                                _ = Nexilis.write(message: CoreMessage_TMessageBank.getCancelCall(fPin: callInfo.callerId, type: !callInfo.isVideo ? "1" : "2"))
                                let center = UNUserNotificationCenter.current()
                                var textCall = ""
                                if !callInfo.isVideo {
                                    textCall = "audio"
                                } else {
                                    textCall = "video"
                                }
                                let content = UNMutableNotificationContent()
                                content.title = callInfo.callerName
                                content.body = "☎️ Missed \(textCall) call".localized()
                                content.userInfo = ["id" : callInfo.callerId, "type" : "CL02", "callType": callInfo.isVideo ? "2" : "1"]
                                content.sound = nil
                                let request = UNNotificationRequest(identifier: callInfo.callerId, content: content, trigger: nil)
                                center.add(request) { error in
                                    if let error = error {
                                        print("Error scheduling notification: \(error.localizedDescription)")
                                    }
                                }
                                Nexilis.saveMessageCall(idCall: (User.getMyPin() ?? "") + CoreMessage_TMessageUtil.getTID(), textMessage: "Missed \(textCall) call".localized() + " at 0", fPin: callInfo.callerId, lPin: (User.getMyPin() ?? ""), timeCall: String(Date().currentTimeMillis()), attachment_type: MessageScope.MISSED_CALL)
                            }
                        } catch {
                            
                        }
                    }
                    APIS.uuidCall = nil
                    Nexilis.callAPNActivated = false
                } else {
                    DispatchQueue.main.async {
                        if APIS.checkAppStateisBackground() {
                            do { try AVAudioSession.sharedInstance().setActive(false) } catch {}
                            API.terminateCall(sParty: nil)
                        }
                    }
                }
            }
        }
        action.fulfill()
    }
}

struct CallInfo {
    let uuid: UUID
    let callerId: String
    let callerName: String
    let isVideo: Bool
    var isAccepted: Bool
}
