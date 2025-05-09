//
//  CommunityModel.swift
//  Pods
//
//  Created by Qindi on 08/05/25.
//

public class CommunityModel: Model {
    public var id: String
    public var name: String
    public var image: String
    public var description: String
    
    public init(id: String, name: String, image: String) {
        self.id = id
        self.name = name
        self.image = image
        self.description = ""
    }
    
    public static func == (lhs: CommunityModel, rhs: CommunityModel) -> Bool {
        return lhs.id == rhs.id
    }
    
}
