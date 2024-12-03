//
//  WhiteboardDelegate.swift
//  Nusa
//
//  Created by Rifqy Fakhrul Rijal on 21/10/19.
//  Copyright © 2019 Development. All rights reserved.
//

import Foundation

public protocol WhiteboardDelegate {
    func draw(x: String, y: String, w: String, h: String, fc: String, sw: String, xo: String, yo: String, data: String)
    func clear()
    func terminate()
}
