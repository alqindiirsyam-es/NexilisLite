//
//  NotifSound.swift
//  NexilisLite
//
//  Created by Akhmad Al Qindi Irsyam on 28/11/22.
//

import Foundation

public class NotifSound: Model {
    public var id: Int
    public var name: String
    public var isSelected: Bool
    public var description: String
    
    public init(id: Int, name: String, isSelected: Bool = false) {
        self.id = id
        self.name = name
        self.isSelected = isSelected
        self.description = ""
    }
    
    public static func == (lhs: NotifSound, rhs: NotifSound) -> Bool {
        return lhs.id == rhs.id
    }
}
