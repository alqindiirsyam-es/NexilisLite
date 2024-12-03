//
//  CallProviderDelegate.swift
//  FloatingButtonApp
//
//  Created by Yayan Dwi on 10/08/21.
//

import Foundation
import UIKit
import CallKit
import AVFoundation
import SwiftUI
import nuSDKService

class CallProviderDelegate: NSObject {
    
    static let providerConfiguration: CXProviderConfiguration = {
        let providerConfiguration = CXProviderConfiguration()
        providerConfiguration.maximumCallsPerCallGroup = 10
        providerConfiguration.maximumCallGroups = 10
        providerConfiguration.supportsVideo = true
        providerConfiguration.supportedHandleTypes = [.phoneNumber]
        //        providerConfiguration.ringtoneSound = "call_in.mp3"
        return providerConfiguration
    }()
    
    let callManager: CallManager
    private let provider: CXProvider
    
    init(callManager: CallManager) {
        self.callManager = callManager
        provider = CXProvider(configuration: type(of: self).providerConfiguration)
        super.init()
        provider.setDelegate(self, queue: nil)
    }
    
    func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((Error?) -> Void)? = nil) {
        let update = CXCallUpdate()
        if let user = User.getData(pin: handle) {
            update.remoteHandle = CXHandle(type: .phoneNumber, value: user.fullName)
        }
        update.hasVideo = hasVideo
        update.supportsGrouping = true
        update.supportsUngrouping = true
        update.supportsHolding = true
        
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if error == nil {
                let call = Call(uuid: uuid)
                call.handle = handle
                call.hasVideo = hasVideo
                
                self.callManager.addCall(call)
            }
            completion?(error)
        }
    }
    
}

extension CallProviderDelegate: CXProviderDelegate {
    
    func providerDidReset(_ provider: CXProvider) {
        //print("providerDidReset...")
        for call in callManager.calls {
            call.endCall()
        }
        callManager.removeAllCalls()
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        //print("CXStartCallAction...\(action.callUUID)")
        let call = Call(uuid: action.callUUID, isOutgoing: true)
        call.handle = action.handle.value
        call.hasStartedConnectingDidChange = { [weak self] in
            self?.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: call.connectingDate)
        }
        call.hasConnectedDidChange = { [weak self] in
            self?.provider.reportOutgoingCall(with: call.uuid, connectedAt: call.connectDate)
        }
        if self.callManager.calls.count > 0 {
            self.callManager.setOnHoldStatus(for: self.callManager.calls.last!, to: true)
        }
        action.fulfill()
        //print("JUMLAH START CALL \(self.callManager.calls.count)")
        self.callManager.addCall(call)
        if self.callManager.calls.count > 1 {
            Nexilis.shared.callManager.startGroupCall(uuid1: call.uuid)
            API.initiateCCall(sParty: call.handle)
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        //print("CXAnswerCallAction...\(action.callUUID)")
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        call.answerCall()
        action.fulfill()
        if call.hasVideo {
            
        } else {
            let controller = QmeraAudioViewController()
            controller.user = User.getData(pin: call.handle)
            controller.isOnGoing = true
            controller.isOutgoing = false
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
            } else {
                if UIApplication.shared.visibleViewController?.navigationController != nil {
                    UIApplication.shared.visibleViewController?.navigationController?.present(controller, animated: true, completion: nil)
                } else {
                    UIApplication.shared.visibleViewController?.present(controller, animated: true, completion: nil)
                }
            }
            
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        //print("CXEndCallAction...\(action.callUUID)")
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        call.endCall()
        action.fulfill()
        self.callManager.removeCall(call)
        //print("JUMLAH CALL \(self.callManager.calls.count)")
        if self.callManager.calls.count == 0, !call.isReceiveEnd {
            //print("MASUK TERMINATE CALL DELEGATE")
            API.terminateCall(sParty: nil)
            DispatchQueue.global().async {
                if let pin = call.handle {
                    _ = Nexilis.write(message: CoreMessage_TMessageBank.endCall(pin: pin))
                }
            }
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        //print("CXSetHeldCallAction...\(action.callUUID)")
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        call.isOnHold = action.isOnHold
//        if call.isOnHold {
//            // pause??
//        } else {
//            // resume??
//        }
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        //print("Timed out", #function)
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        //print("Received", #function)
        
        /*
         Start call audio media, now that the audio session is activated,
         after having its priority elevated.
         */
        if let call = self.callManager.calls.last {
            if call.isOutgoing {
                API.initiateCCall(sParty: call.handle)
            } else {
                API.receiveCCall(sParty: call.handle)
            }
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        //print("CXGroupCallAction...\(action.callUUID)")
        // perform merge call here where you merge ports of two call audio i/o
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        //print("Received", #function)
        /*
         Restart any non-call related audio now that the app's audio session is deactivated,
         after having its priority restored to normal.
         */
    }
    
}
