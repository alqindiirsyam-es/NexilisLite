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
    var activeCalls: [UUID: CallInfo] = [:]
        
    private let provider: CXProvider
    private let callController = CXCallController()
    
    override init() {
        // Fix: force-cast. An app whose Info.plist has no CFBundleName - or has it as anything
        // but a string - crashed the first time anything touched CallManager, which is in the
        // middle of an incoming call.
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
            ?? "Call"
        let providerConfiguration = CXProviderConfiguration(localizedName: appName)
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
    
    /// Tells the system a call is being placed from this app.
    ///
    /// There is no such thing as a "CallKit screen" for an outgoing call - iOS provides a native
    /// screen only for *incoming* ones. What reporting an outgoing call does give is everything
    /// else the system does for a real call: the green in-call indicator, an entry in the phone's
    /// Recents, the call showing as busy to anything else that tries to start one, and the audio
    /// session handled by CallKit rather than by the app alone. That is exactly what WhatsApp
    /// does for its outgoing calls, and it was never being done here - startCall had no handler
    /// for the action it requested, so the transaction failed and nothing was reported at all.
    public func startOutgoingCall(uuid: UUID, calleeName: String, calleeId: String, isVideo: Bool) {
        // Fix: a call the system still has on its books refuses a new one - this provider allows
        // a single call group at a time - and one gets left behind easily: endCall used to drop
        // its completion when the request failed, so the caller never cleared its own record of
        // it. The result was an outgoing call that reported nothing at all, silently, for the
        // rest of the session. Everything still known is cleared first, and the new call is only
        // asked for once that has actually gone through.
        endEveryKnownCall { [weak self] in
            guard let self = self else {
                return
            }
            let handle = CXHandle(type: .generic, value: calleeId)
            let startCallAction = CXStartCallAction(call: uuid, handle: handle)
            startCallAction.contactIdentifier = calleeName
            startCallAction.isVideo = isVideo
            self.activeCalls[uuid] = CallInfo(uuid: uuid, callerId: calleeId, callerName: calleeName, isVideo: isVideo, isAccepted: true, isOutgoing: true, answersOverSocket: false, isEndingLocally: false)

            self.callController.request(CXTransaction(action: startCallAction)) { error in
                if let error = error {
                    // Worth seeing: when this fails the call runs with the system knowing
                    // nothing about it - no in-call indicator, nothing in Recents.
                    print("CallKit refused the outgoing call: \(error.localizedDescription)")
                    self.activeCalls[uuid] = nil
                    return
                }
                // The rest happens in the start-call action above, which the system performs next.
            }
        }
    }

    /// Clears every call this object still believes is running, and only then carries on.
    private func endEveryKnownCall(completion: @escaping () -> Void) {
        let uuids = Array(activeCalls.keys)
        guard !uuids.isEmpty else {
            completion()
            return
        }
        let group = DispatchGroup()
        for uuid in uuids {
            activeCalls[uuid]?.isEndingLocally = true
            group.enter()
            callController.request(CXTransaction(action: CXEndCallAction(call: uuid))) { _ in
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion()
        }
    }

    /// Corrects what the system shows for a call already reported - the name is often only
    /// looked up after the call has been placed.
    public func updateCall(uuid: UUID, callerName: String) {
        guard var callInfo = activeCalls[uuid], !callerName.isEmpty, callInfo.callerName != callerName else {
            return
        }
        callInfo.callerName = callerName
        activeCalls[uuid] = callInfo
        let update = CXCallUpdate()
        update.localizedCallerName = callerName
        update.remoteHandle = CXHandle(type: .generic, value: callInfo.callerId)
        provider.reportCall(with: uuid, updated: update)
    }

    /// The other side picked up: from here the system counts the duration instead of showing
    /// "connecting...". Safe to call more than once - the pick-up is noticed from more than one
    /// place, and only the first report means anything.
    public func reportOutgoingCallConnected(uuid: UUID) {
        guard var callInfo = activeCalls[uuid], callInfo.isOutgoing, !callInfo.isConnectedReported else {
            return
        }
        callInfo.isConnectedReported = true
        activeCalls[uuid] = callInfo
        provider.reportOutgoingCall(with: uuid, connectedAt: nil)
    }
    
    /// - Parameters:
    ///   - answersOverSocket: true when the call is already coming in over the live connection
    ///     rather than having woken the app with a push. Answering one of those is the same
    ///     thing the app's own accept button does - see the answer action below - and it must
    ///     not go through the push flow, which re-initialises the connection first.
    ///   - onFailure: called when the system refuses the call, so the caller can fall back to
    ///     showing the app's own incoming screen instead of the reader missing the call.
    public func reportIncomingCall(uuid: UUID, callerName: String, callerId: String, isVideo: Bool, isAutoCancel: Bool = false, answersOverSocket: Bool = false, onFailure: (() -> Void)? = nil) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: callerId)
        update.localizedCallerName = callerName
        update.hasVideo = isVideo
        activeCalls[uuid] = CallInfo(uuid: uuid, callerId: callerId, callerName: callerName, isVideo: isVideo, isAccepted: false, isOutgoing: false, answersOverSocket: answersOverSocket, isEndingLocally: false)

        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error = error {
                print("Error reporting incoming call: \(error.localizedDescription)")
                self.activeCalls[uuid] = nil
                DispatchQueue.main.async {
                    onFailure?()
                }
                return
            }
            if isAutoCancel {
                self.endCall(uuid: uuid) {
                    
                }
            }
        }
    }
    
    public func endCall(uuid: UUID, completion: @escaping () -> ()) {
        // Ending from inside the app: the app has already done, or is doing, everything the end
        // needs. Marked so the action below does not send the hang-up a second time.
        activeCalls[uuid]?.isEndingLocally = true
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)

        callController.request(transaction) { error in
            // Fix: the completion used to be skipped when the request failed - and it is what
            // callers use to forget the call (APIS.uuidCall = nil). A failure therefore left a
            // uuid behind pointing at a call that no longer exists, which is exactly what blocks
            // the next one from being reported. Either way the app is done with this call.
            if let error = error {
                print("Failed to end call: \(error.localizedDescription)")
            }
            self.activeCalls[uuid] = nil
            completion()
        }
    }
    
}

extension CallManager: CXProviderDelegate {
    public func providerDidReset(_ provider: CXProvider) {
    }
    
    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        let uuid = action.callUUID
        // Fix: fulfilled up front. Both of the early returns below - the ones that dismiss an
        // alert before presenting - skipped the single fulfil at the end of this method, so on
        // those routes the system was left waiting for an answer that never came and timed the
        // action out. Accepting the call is decided here; putting the screen up is this app's
        // own business and nothing the system needs to wait for.
        action.fulfill()
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
                if callInfo.answersOverSocket {
                    // Already ringing over the live connection: this is the accept button on the
                    // app's own screen, pressed from the system's call UI instead. autoAcceptAPN
                    // would take the other road - re-initialise the connection and announce the
                    // call afresh - which is only right for a call that woke the app with a push.
                    controller.isOnGoing = true
                    API.receiveCCall(sParty: callInfo.callerId)
                } else {
                    controller.autoAcceptAPN = true
                }
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
    }
    
    private func rootWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first{$0.activationState == .foregroundActive}
    }
    
    /// The system asking this app to place the call it was told about.
    ///
    /// Fix: there was no handler for this at all. A CXStartCallAction with nobody to perform it
    /// simply times out, so the outgoing call was never reported and the phone never treated it
    /// as a call - no in-call indicator, nothing in Recents, and the audio session left entirely
    /// to the app. The call itself is placed by the screen that asked for it; all that is needed
    /// here is to accept the action and tell the system it is connecting.
    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        action.fulfill()
        // Fix: the system was showing the callee's pin. It draws CXHandle.value, and the name
        // was only put in contactIdentifier - which is for matching a contact in the address
        // book, not for display. localizedCallerName is the one it shows, and it has to come
        // through a call update: the start action cannot carry it.
        if let name = activeCalls[action.callUUID]?.callerName, !name.isEmpty {
            let update = CXCallUpdate()
            update.localizedCallerName = name
            update.remoteHandle = action.handle
            provider.reportCall(with: action.callUUID, updated: update)
        }
        // From here the phone treats it as a call being placed: the in-call pill, the card in
        // the app switcher and the entry in Recents all appear now, not when it is answered.
        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: nil)
    }

    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        // Fix: this used to run only when the call had come in through a push
        // (Nexilis.callAPNActivated). A call reported to the system any other way - an outgoing
        // one, or one ringing over the live connection - could be hung up from the system's own
        // call UI and nothing at all would happen.
        let uuid = action.callUUID
        guard let callInfo = activeCalls[uuid] else {
            action.fulfill()
            return
        }
        activeCalls[uuid] = nil
        // The app is ending it itself and has already done everything below; this action is only
        // the system being told to close its side.
        guard !callInfo.isEndingLocally else {
            action.fulfill()
            return
        }
        let textCall = callInfo.isVideo ? "video" : "audio"

        if callInfo.isAccepted {
            DispatchQueue.main.async {
                do { try AVAudioSession.sharedInstance().setActive(false) } catch {}
                API.terminateCall(sParty: nil)
            }
            APIS.uuidCall = nil
            Nexilis.callAPNActivated = false
            action.fulfill()
            return
        }

        if callInfo.answersOverSocket {
            // Turned down while the app was in front. The connection is live, so this is what
            // the reject button on the app's own screen does - stop the call and note the one
            // that was missed. No notification: the reader is holding the phone, they have just
            // declined it themselves.
            DispatchQueue.main.async {
                Nexilis.stopRingtoneCall()
                API.terminateCall(sParty: nil)
            }
            Nexilis.saveMessageCall(idCall: (User.getMyPin() ?? "") + CoreMessage_TMessageUtil.getTID(), textMessage: "Missed \(textCall) call".localized() + " at 0", fPin: callInfo.callerId, lPin: (User.getMyPin() ?? ""), timeCall: String(Date().currentTimeMillis()), attachment_type: MessageScope.MISSED_CALL)
            APIS.uuidCall = nil
            action.fulfill()
            return
        }

        // Turned down, or never answered, while the app was not running: tell the other side and
        // leave a missed call behind.
        DispatchQueue.global().async {
            if API.nGetCLXConnState() == 0 {
                _ = Nexilis.justInit()
            }
            _ = Nexilis.write(message: CoreMessage_TMessageBank.getCancelCall(fPin: callInfo.callerId, type: callInfo.isVideo ? "2" : "1"))
            let content = UNMutableNotificationContent()
            content.title = callInfo.callerName
            content.body = "☎️ Missed \(textCall) call".localized()
            content.userInfo = ["id" : callInfo.callerId, "type" : "CL02", "callType": callInfo.isVideo ? "2" : "1"]
            content.sound = nil
            let request = UNNotificationRequest(identifier: callInfo.callerId, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
            Nexilis.saveMessageCall(idCall: (User.getMyPin() ?? "") + CoreMessage_TMessageUtil.getTID(), textMessage: "Missed \(textCall) call".localized() + " at 0", fPin: callInfo.callerId, lPin: (User.getMyPin() ?? ""), timeCall: String(Date().currentTimeMillis()), attachment_type: MessageScope.MISSED_CALL)
        }
        APIS.uuidCall = nil
        Nexilis.callAPNActivated = false
        action.fulfill()
    }
}

struct CallInfo {
    let uuid: UUID
    let callerId: String
    var callerName: String
    let isVideo: Bool
    var isAccepted: Bool
    var isOutgoing: Bool = false
    /// Answering this one means answering over the connection the app already has, the way the
    /// accept button on the app's own screen does.
    var answersOverSocket: Bool = false
    /// The app is ending it itself; the end action has nothing left to do.
    var isEndingLocally: Bool = false
    /// Whether the system has already been told this outgoing call was picked up. Telling it
    /// twice is pointless, and the pick-up is noticed from more than one place.
    var isConnectedReported: Bool = false
}
