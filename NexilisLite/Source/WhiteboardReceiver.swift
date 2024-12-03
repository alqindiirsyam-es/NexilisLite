//
//  WhiteboardReceiver.swift
//  Nusa
//
//  Created by Rifqy Fakhrul Rijal on 21/10/19.
//  Copyright © 2019 Development. All rights reserved.
//

import Foundation

public protocol WhiteboardReceiver {
    func cancel(roomId: String)
    func incomingWB(roomId: String)
}
