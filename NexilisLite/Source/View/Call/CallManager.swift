//
//  CallManager.swift
//  FloatingButtonApp
//
//  Created by Yayan Dwi on 10/08/21.
//

import Foundation
import CallKit

final class CallManager: NSObject, ObservableObject {
    
    let callController = CXCallController()
    
    func startCall(handle: String, video: Bool = false) {
        let cx = CXHandle(type: .phoneNumber, value: handle)
        let startCallAction = CXStartCallAction(call: UUID(), handle: cx)
        
        startCallAction.isVideo = video
        
        let transaction = CXTransaction()
        transaction.addAction(startCallAction)
        
        requestTransaction(transaction)
    }
    
    func end(call: Call) {
        let endCallAction = CXEndCallAction(call: call.uuid)
        let transaction = CXTransaction()
        transaction.addAction(endCallAction)
        
        requestTransaction(transaction)
    }
    
    func setOnHoldStatus(for call: Call, to onHold: Bool) {
        let setHeldCallAction = CXSetHeldCallAction(call: call.uuid, onHold: onHold)
        let transaction = CXTransaction()
        transaction.addAction(setHeldCallAction)
        
        requestTransaction(transaction)
    }
    
    func startGroupCall(uuid1: UUID) {
        let call1UUID = calls[0].uuid
        let call2UUID = uuid1
        let mergeCallAction = CXSetGroupCallAction(call: call1UUID, callUUIDToGroupWith: call2UUID)

        let transaction = CXTransaction()
        transaction.addAction(mergeCallAction)
        
        requestTransaction(transaction)
    }
    
    private func requestTransaction(_ transaction: CXTransaction) {
        callController.request(transaction) { error in
//            if let error = error {
//                //print("Error requesting transaction:", error.localizedDescription)
//            } else {
//                //print("Requested transaction successfully")
//            }
        }
    }
    
    @Published private(set) var calls = [Call]()
    
    func callWithUUID(uuid: UUID) -> Call? {
        guard let index = calls.firstIndex(where: { $0.uuid == uuid }) else { return nil }
        
        return calls[index]
    }
    
    func call(with handle: String) -> Call? {
        guard let index = calls.firstIndex(where: { $0.handle == handle }) else { return nil }
        
        return calls[index]
    }
    
    func addCall(_ call: Call) {
        calls.append(call)
    }
    
    func removeCall(_ call: Call) {
        guard let index = calls.firstIndex(where: { $0 === call }) else { return }
        
        calls.remove(at: index)
    }
    
    func removeAllCalls() {
        calls.removeAll()
    }
    
}
