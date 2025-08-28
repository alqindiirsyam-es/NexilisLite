//
//  FormItem.swift
//  Pods
//
//  Created by Qindi on 27/08/25.
//

import Foundation

public class FormItemM: Model {
    public var formId: String
    public var label: String
    public var value: String
    public var key: String
    public var sqNo: Int64
    public var type: String
    public var background: String
    public var color: String
    public var description: String
    
    public init(formId: String, label: String, value: String, key: String, sqNo: Int64, type: String, background: String, color: String) {
        self.formId = formId
        self.label = label
        self.value = value
        self.key = key
        self.sqNo = sqNo
        self.type = type
        self.background = background
        self.color = color
        self.description = ""
    }
    
    public init(formId: String) {
        self.formId = formId
        self.label = ""
        self.value = ""
        self.key = ""
        self.sqNo = 0
        self.type = ""
        self.background = ""
        self.color = ""
        self.description = ""
    }
    
    public static func == (lhs: FormItemM, rhs: FormItemM) -> Bool {
        return lhs.formId == rhs.formId
    }
    
}
