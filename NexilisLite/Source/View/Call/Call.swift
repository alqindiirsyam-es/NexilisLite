//
//  Call.swift
//  FloatingButtonApp
//
//  Created by Yayan Dwi on 10/08/21.
//

import Foundation

final class Call: ObservableObject {
    
    let uuid: UUID
    let isOutgoing: Bool
    var handle: String?
    var hasVideo: Bool = false
    var isReceiveEnd: Bool = false
    
    init(uuid: UUID, isOutgoing: Bool = false) {
        self.uuid = uuid
        self.isOutgoing = isOutgoing
    }
    
    var stateDidChange: (() -> Void)?
    var hasStartedConnectingDidChange: (() -> Void)?
    var hasConnectedDidChange: (() -> Void)?
    var hasEndedDidChange: (() -> Void)?
    
    var connectingDate: Date? {
        didSet {
            stateDidChange?()
            hasStartedConnectingDidChange?()
        }
    }
    
    var connectDate: Date? {
        didSet {
            stateDidChange?()
            hasConnectedDidChange?()
        }
    }
    
    var endDate: Date? {
        didSet {
            stateDidChange?()
            hasEndedDidChange?()
        }
    }
    
    var isOnHold = false {
        didSet {
            stateDidChange?()
        }
    }
    
    var hasStartedConnecting: Bool {
        get {
            return connectingDate != nil
        }
        set {
            connectingDate = newValue ? Date() : nil
        }
    }
    
    var hasConnected: Bool {
        get {
            return connectDate != nil
        }
        set {
            connectDate = newValue ? Date() : nil
        }
    }
    
    var hasEnded: Bool {
        get {
            return endDate != nil
        }
        set {
            endDate = newValue ? Date() : nil
        }
    }
    
    var duration: TimeInterval {
        guard let connectDate = connectDate else {
            return 0
        }
        
        return Date().timeIntervalSince(connectDate)
    }
    
    func connectingCall() {
        hasStartedConnecting = true
    }
    
    func answerCall() {
        hasConnected = true
    }
    
    func endCall() {
        hasEnded = true
    }
    
    func reconnectingCall() {
        hasEnded = false
    }
}
