//
//  Form.swift
//  Pods
//
//  Created by Qindi on 27/08/25.
//

import Foundation

public class FormM: Model {
    public var formId: String
    public var title: String
    public var createdDate: String
    public var createdBy: String
    public var sqNo: Int64
    public var iconTitle: String
    public var iconSuffix: String
    public var footer: String
    public var description: String
    
    public init(formId: String, title: String, createdDate: String, createdBy: String, sqNo: Int64, iconTitle: String, iconSuffix: String, footer: String) {
        self.formId = formId
        self.title = title
        self.createdDate = createdDate
        self.createdBy = createdBy
        self.sqNo = sqNo
        self.iconTitle = iconTitle
        self.iconSuffix = iconSuffix
        self.footer = footer
        self.description = ""
    }
    
    public static func == (lhs: FormM, rhs: FormM) -> Bool {
        return lhs.formId == rhs.formId
    }
    
}
