//
//  Call.swift
//  Pods
//
//  Created by Qindi on 09/04/25.
//

import Foundation

public class CallModel: Model {
    public var fPin: String
    public var name: String
    public var image: String
    public var time: String
    public var isVideo: Bool
    public var status: String
    public var description: String
    
    public init(fPin: String, name: String, image: String, time: String, isVideo: Bool, status: String) {
        self.fPin = fPin
        self.name = name
        self.image = image
        self.time = time
        self.isVideo = isVideo
        self.status = status
        self.description = ""
    }
    
    public static func == (lhs: CallModel, rhs: CallModel) -> Bool {
        return lhs.fPin == rhs.fPin
    }
    
}
